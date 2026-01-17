import SwiftUI

/// Displays a single word with ORP highlighting
struct WordDisplayView: View {
    let word: String
    let orpMode: ORPCalculator.Mode
    
    // Accent color for ORP letter
    private let accentColor = Color(red: 1.0, green: 0.3, blue: 0.3) // Vibrant red
    
    var body: some View {
        HStack(spacing: 0) {
            let parts = ORPCalculator.splitWord(word, mode: orpMode)
            
            // Prefix (before ORP)
            Text(parts.prefix)
                .foregroundColor(.white)
            
            // ORP letter (highlighted)
            Text(parts.orp)
                .foregroundColor(accentColor)
            
            // Suffix (after ORP)
            Text(parts.suffix)
                .foregroundColor(.white)
        }
        .font(.system(size: 72, weight: .medium, design: .monospaced))
        .frame(maxWidth: .infinity)
    }
}

/// Visual guide lines for ORP alignment (optional enhancement)
struct ORPGuideView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 20)
            
            Spacer()
                .frame(height: 80)
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 20)
        }
    }
}

#Preview {
    WordDisplayView(word: "Reading", orpMode: .spritz)
        .background(Color.black)
}
