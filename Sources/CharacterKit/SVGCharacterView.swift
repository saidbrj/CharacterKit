import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

#if canImport(UIKit)
public struct SVGWebView: UIViewRepresentable {
    public let svgContent: String

    public init(svgContent: String) {
        self.svgContent = svgContent
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    background: transparent;
                    overflow: hidden;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                svg {
                    width: 100%;
                    height: 100%;
                    max-width: 100%;
                    max-height: 100%;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(svgContent)
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
#endif

public struct SVGCharacterView: View {
    public var mood: String
    public var onEvent: ((CharacterEvent) -> Void)?

    @State private var bounceScaleX: CGFloat = 1.0
    @State private var bounceScaleY: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var isBreathing = false

    public init(
        mood: String = "neutral",
        onEvent: ((CharacterEvent) -> Void)? = nil
    ) {
        self.mood = mood.lowercased()
        self.onEvent = onEvent
    }

    private var currentSVG: String {
        if let emotion = BlobbyEmotion(rawValue: mood) {
            return emotion.svgString
        }
        return BlobbyEmotion.neutral.svgString
    }

    public var body: some View {
        ZStack {
            #if canImport(UIKit)
            SVGWebView(svgContent: currentSVG)
                .id(mood)
                .aspectRatio(320.0 / 300.0, contentMode: .fit)
            #endif
        }
        .scaleEffect(
            x: bounceScaleX * (isBreathing ? 1.015 : 0.985),
            y: bounceScaleY * (isBreathing ? 0.985 : 1.02)
        )
        .offset(dragOffset)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = CGSize(
                        width: value.translation.width * 0.15,
                        height: value.translation.height * 0.15
                    )
                    bounceScaleX = 1.0 + (abs(value.translation.width) * 0.001)
                    bounceScaleY = 1.0 - (abs(value.translation.height) * 0.001)
                }
                .onEnded { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance < 10 {
                        handleTap()
                    } else {
                        onEvent?(.dragEnded)
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                        dragOffset = .zero
                        bounceScaleX = 1.0
                        bounceScaleY = 1.0
                    }
                }
        )
    }

    private func handleTap() {
        onEvent?(.tap)
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif

        withAnimation(.easeOut(duration: 0.08)) {
            bounceScaleX = 1.15
            bounceScaleY = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5, blendDuration: 0)) {
                bounceScaleX = 1.0
                bounceScaleY = 1.0
            }
        }
    }
}
