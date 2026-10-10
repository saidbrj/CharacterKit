import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Things the character noticed. Use these to trigger sounds, score points, etc.
public enum CharacterEvent: Equatable {
    case tap
    case longPress
    case dragBegan
    case dragEnded
}

/// An interactive character.
///
///     CharacterView(spec: spec, mood: "happy") { event in
///         print(event)
///     }
///
/// - `spec`: a character exported from the editor (see `CharacterSpec.load(from:)`).
/// - `mood`: the name of the expression to rest in. Change it any time and the face eases to it.
public struct CharacterView: View {
    private let spec: CharacterSpec
    private let mood: String
    private let onEvent: ((CharacterEvent) -> Void)?

    @State private var rig = RigState()
    @State private var touchStartTime: TimeInterval = 0
    @State private var isLongPressActive: Bool = false
    @State private var lastTapTime: TimeInterval = 0
    @State private var holdTask: Task<Void, Never>? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        spec: CharacterSpec,
        mood: String = "neutral",
        onEvent: ((CharacterEvent) -> Void)? = nil
    ) {
        self.spec = spec.sanitized()
        self.mood = mood
        self.onEvent = onEvent
    }

    public var body: some View {
        rig.baseMood = mood
        let isFill = (spec.layout.mode.lowercased() == "fill")

        let content = GeometryReader { geo in
            let viewSize = geo.size
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    rig.baseMood = mood
                    rig.step(
                        now: timeline.date.timeIntervalSinceReferenceDate,
                        spec: spec,
                        reduceMotion: reduceMotion
                    )
                    CharacterRenderer.draw(context, size: size, spec: spec, rig: rig)
                }
                .frame(width: viewSize.width, height: viewSize.height)
            }
            .frame(width: viewSize.width, height: viewSize.height)
            .contentShape(Rectangle())
            .gesture(dragGesture(in: viewSize))
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        handleTap()
                    }
            )
        }

        return Group {
            if isFill {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                content
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    // MARK: Gestures

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !rig.touching {
                    rig.touching = true
                    rig.moved = false
                    touchStartTime = RigState.now
                    isLongPressActive = false

                    holdTask?.cancel()
                    let holdDuration = spec.touch.holdSeconds
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
                        if !Task.isCancelled && rig.touching && !rig.moved && !isLongPressActive {
                            isLongPressActive = true
                            handleLongPress()
                        }
                    }
                }

                let distance = hypot(value.translation.width, value.translation.height)
                if distance > 10 && !rig.moved {
                    rig.moved = true
                    holdTask?.cancel()
                    holdTask = nil
                    onEvent?(.dragBegan)
                }

                // Guide the character's pupils towards the finger/cursor
                if spec.touch.dragLooksAt {
                    rig.lookTarget = normalized(value.location, in: size)
                }
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                let elapsed = RigState.now - touchStartTime

                holdTask?.cancel()
                holdTask = nil

                rig.touching = false
                rig.lookTarget = nil
                rig.moved = false

                if isLongPressActive {
                    isLongPressActive = false
                    if let held = rig.heldReaction {
                        rig.react(held, seconds: spec.touch.reactSeconds)
                        rig.heldReaction = nil
                    }
                } else if distance < 20 && elapsed < spec.touch.holdSeconds {
                    handleTap()
                } else {
                    onEvent?(.dragEnded)
                }
            }
    }

    private func handleTap() {
        let now = RigState.now
        guard now - lastTapTime > 0.2 else { return }
        lastTapTime = now

        if let name = spec.touch.tap {
            rig.react(name, seconds: spec.touch.reactSeconds)
        }
        if !reduceMotion {
            rig.bump(6 * spec.touch.tapBounce, earFlick: spec.touch.earFlick)
        }
        haptic()
        onEvent?(.tap)
    }

    private func handleLongPress() {
        if let name = spec.touch.longPress {
            rig.heldReaction = name
            rig.react(name, seconds: 600)   // held until finger lifts
        }
        haptic()
        onEvent?(.longPress)
    }

    // MARK: Helpers

    private func normalized(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let halfW = max(size.width / 2.0, 1.0)
        let halfH = max(size.height / 2.0, 1.0)
        let x = (point.x - size.width / 2.0) / halfW
        let y = (point.y - size.height / 2.0) / halfH
        return CGPoint(
            x: max(-1.0, min(1.0, x * 2.2)),
            y: max(-1.0, min(1.0, y * 2.2))
        )
    }

    private func haptic() {
        #if canImport(UIKit) && !os(tvOS)
        guard spec.touch.haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
