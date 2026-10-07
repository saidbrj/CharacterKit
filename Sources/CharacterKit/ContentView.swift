import SwiftUI

public struct ContentView: View {
    private let spec: CharacterSpec
    @State private var mood: String

    public init(spec: CharacterSpec = .current, mood: String? = nil) {
        self.spec = spec.sanitized()
        _mood = State(initialValue: mood ?? spec.sanitized().defaultMood)
    }

    public var body: some View {
        VStack(spacing: 24) {
            CharacterView(spec: spec, mood: mood) { event in
                print(event)
            }
            .frame(width: 280)

            // Emotion switcher driven by spec.expressionOrder
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spec.expressionOrder, id: \.self) { emotion in
                        Button(emotion.capitalized) {
                            mood = emotion
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(mood == emotion ? Color(characterHex: spec.palette.bodyShade) : Color.gray.opacity(0.3))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
