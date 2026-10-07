import SwiftUI

/// A ready-made playground: tap, hold and drag the character, and switch its mood.
/// Drop it into any screen while you integrate.
public struct CharacterDemoView: View {
    private let spec: CharacterSpec
    @State private var mood: String
    @State private var lastEvent = "none yet"

    public init(spec: CharacterSpec = .current) {
        let sanitizedSpec = spec.sanitized()
        self.spec = sanitizedSpec
        _mood = State(initialValue: sanitizedSpec.defaultMood)
    }

    public var body: some View {
        VStack(spacing: 24) {
            CharacterView(spec: spec, mood: mood) { event in
                lastEvent = "\(event)"
            }
            .frame(maxWidth: 320)

            Text("Last event: \(lastEvent)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spec.expressionOrder, id: \.self) { name in
                        Button(name.capitalized) { mood = name }
                            .buttonStyle(.borderedProminent)
                            .tint(name == mood ? Color(characterHex: spec.palette.bodyShade) : Color.gray)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    CharacterDemoView()
}
#endif
