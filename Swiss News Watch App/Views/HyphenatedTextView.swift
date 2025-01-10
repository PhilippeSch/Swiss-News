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
        var attributedString = AttributedString()
        
        // Split the text into paragraphs
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for (index, paragraph) in paragraphs.enumerated() {
            var paragraphString = AttributedString(paragraph)
            
            // Apply bold font to subtitles (first paragraph)
            if index == 0 {
                paragraphString.font = .footnote.bold()
            } else {
                paragraphString.font = .footnote
            }
            
            // Add paragraph to main string
            if index > 0 {
                attributedString += AttributedString("\n\n")
            }
            attributedString += paragraphString
        }
        
        return attributedString
    }
} 