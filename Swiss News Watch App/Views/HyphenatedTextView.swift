import SwiftUI

struct HyphenatedTextView: View {
    let text: String
    let subtitles: Set<String>
    
    var body: some View {
        Text(attributedString)
            .lineSpacing(2)
            .multilineTextAlignment(.leading)
            .environment(\.locale, Locale(identifier: "de_CH"))
            .allowsTightening(true)
            .lineLimit(nil)
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString()
        
        // Split the text into paragraphs
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for (index, paragraph) in paragraphs.enumerated() {
            var paragraphString = AttributedString(paragraph)
            
            // Make paragraph bold if it's a subtitle
            paragraphString.font = subtitles.contains(paragraph) ? .footnote.bold() : .footnote
            
            // Add paragraph to main string
            if index > 0 {
                attributedString += AttributedString("\n\n")
            }
            attributedString += paragraphString
        }
        
        return attributedString
    }
}

// Helper for cleaner NSMutableParagraphStyle configuration
extension NSMutableParagraphStyle {
    func apply(_ block: (NSMutableParagraphStyle) -> Void) -> NSMutableParagraphStyle {
        block(self)
        return self
    }
} 
