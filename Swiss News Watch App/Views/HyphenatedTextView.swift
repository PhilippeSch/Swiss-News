import SwiftUI

struct HyphenatedTextView: View {
    let text: String
    
    var body: some View {
        Text(attributedString)
            .font(.footnote)
            .lineSpacing(2)
            .multilineTextAlignment(.leading)
            .environment(\.locale, Locale(identifier: "de_CH"))
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        attributedString.font = .footnote
        return attributedString
    }
} 