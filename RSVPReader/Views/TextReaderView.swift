import SwiftUI

/// Full text reader view where users can click on any word to start reading from there
struct TextReaderView: View {
    @ObservedObject var engine: RSVPEngine
    @Binding var isVisible: Bool
    let onWordSelected: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Click any word to start reading from there")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.9))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Scrollable text content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(engine.paragraphs) { paragraph in
                            ParagraphTextView(
                                paragraph: paragraph,
                                currentWordIndex: engine.currentIndex,
                                onWordTap: { wordIndex in
                                    onWordSelected(wordIndex)
                                }
                            )
                            .id(paragraph.id)
                        }
                    }
                    .padding(24)
                }
                .onAppear {
                    // Scroll to current paragraph
                    withAnimation {
                        proxy.scrollTo(engine.currentParagraphIndex, anchor: .center)
                    }
                }
            }
        }
        .background(Color(white: 0.08))
    }
}

/// A single paragraph with clickable words
struct ParagraphTextView: View {
    let paragraph: Paragraph
    let currentWordIndex: Int
    let onWordTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Paragraph number badge
            Text("¶ \(paragraph.id + 1)")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
            
            // Word flow
            WordFlowLayout(paragraph: paragraph, currentWordIndex: currentWordIndex, onWordTap: onWordTap)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(paragraph.wordRange.contains(currentWordIndex) ? Color.white.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(paragraph.wordRange.contains(currentWordIndex) ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

/// Custom layout that wraps words like text
struct WordFlowLayout: View {
    let paragraph: Paragraph
    let currentWordIndex: Int
    let onWordTap: (Int) -> Void
    
    var body: some View {
        // Use a wrapping HStack via FlowLayout
        let words = paragraph.text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        WrappingHStack(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let globalIndex = paragraph.wordRange.lowerBound + index
                WordButton(
                    word: word,
                    isCurrent: globalIndex == currentWordIndex,
                    isPast: globalIndex < currentWordIndex,
                    onTap: { onWordTap(globalIndex) }
                )
            }
        }
    }
}

/// A single clickable word
struct WordButton: View {
    let word: String
    let isCurrent: Bool
    let isPast: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Text(word)
            .font(.system(size: 15))
            .foregroundColor(
                isCurrent ? .red :
                isPast ? .white.opacity(0.4) :
                isHovering ? .white : .white.opacity(0.7)
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isCurrent ? Color.red.opacity(0.2) :
                        isHovering ? Color.white.opacity(0.1) : Color.clear
                    )
            )
            .onTapGesture { onTap() }
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

/// A simple wrapping horizontal stack (Flow Layout)
struct WrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            let position = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: position, proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
            maxHeight = max(maxHeight, currentY + rowHeight)
        }
        
        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}

#Preview {
    TextReaderView(
        engine: RSVPEngine(),
        isVisible: .constant(true),
        onWordSelected: { _ in }
    )
    .frame(width: 600, height: 400)
}
