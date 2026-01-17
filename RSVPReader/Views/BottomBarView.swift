import SwiftUI

/// Bottom bar showing progress, WPM, and controls hint
struct BottomBarView: View {
    @ObservedObject var engine: RSVPEngine
    let fileName: String
    @Binding var showSidebar: Bool
    @Binding var showTextReader: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: engine.progress)
                .progressViewStyle(.linear)
                .tint(Color.white.opacity(0.3))
            
            // Info row
            HStack {
                // Sidebar toggle button
                Button(action: { showSidebar.toggle() }) {
                    Image(systemName: showSidebar ? "sidebar.left" : "sidebar.left")
                        .font(.caption)
                        .foregroundColor(.white.opacity(showSidebar ? 0.7 : 0.4))
                }
                .buttonStyle(.plain)
                .help("Toggle sidebar (⌘S)")
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                // Text reader toggle button
                Button(action: { showTextReader.toggle() }) {
                    Image(systemName: "text.page")
                        .font(.caption)
                        .foregroundColor(.white.opacity(showTextReader ? 0.7 : 0.4))
                }
                .buttonStyle(.plain)
                .help("Open text reader (⌘R)")
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                // File name
                Text(fileName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                
                Spacer()
                
                // Paragraph indicator
                if !engine.paragraphs.isEmpty {
                    Text("¶ \(engine.currentParagraphIndex + 1)/\(engine.paragraphs.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Play state indicator
                Image(systemName: engine.isPlaying ? "play.fill" : "pause.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                // WPM display
                Text("\(engine.wordsPerMinute) WPM")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.5))
                
                // Word counter
                Text("\(engine.currentIndex + 1)/\(engine.totalWords)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Keyboard hints
            HStack(spacing: 12) {
                KeyHint(key: "Space", action: "Play")
                KeyHint(key: "←→", action: "Words")
                KeyHint(key: "↑↓", action: "Speed")
                KeyHint(key: "⌘R", action: "Reader")
                KeyHint(key: "Esc", action: "Close")
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

/// Small keyboard hint display
struct KeyHint: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
            
            Text(action)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.3))
        }
        .foregroundColor(.white.opacity(0.5))
    }
}

#Preview {
    VStack {
        Spacer()
        BottomBarView(
            engine: RSVPEngine(),
            fileName: "sample.txt",
            showSidebar: .constant(true),
            showTextReader: .constant(false)
        )
    }
    .background(Color.black)
}
