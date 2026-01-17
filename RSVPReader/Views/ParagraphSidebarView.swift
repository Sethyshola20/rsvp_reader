import SwiftUI

/// Sidebar showing paragraphs for navigation
struct ParagraphSidebarView: View {
    @ObservedObject var engine: RSVPEngine
    let isVisible: Bool
    
    var body: some View {
        if isVisible && !engine.paragraphs.isEmpty {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(engine.paragraphs) { paragraph in
                            ParagraphRowView(
                                paragraph: paragraph,
                                isCurrent: paragraph.id == engine.currentParagraphIndex,
                                onTap: {
                                    engine.goToParagraph(paragraph)
                                }
                            )
                            .id(paragraph.id)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .onChange(of: engine.currentParagraphIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .frame(width: 280)
            .background(Color.black.opacity(0.95))
        }
    }
}

/// Single paragraph row in the sidebar
struct ParagraphRowView: View {
    let paragraph: Paragraph
    let isCurrent: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                // Paragraph number
                Text("\(paragraph.id + 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(isCurrent ? .red : .white.opacity(0.3))
                    .frame(width: 24, alignment: .trailing)
                
                // Preview text
                Text(paragraph.preview)
                    .font(.system(size: 12))
                    .foregroundColor(isCurrent ? .white : .white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrent ? Color.white.opacity(0.1) : (isHovering ? Color.white.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isCurrent ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        ParagraphSidebarView(engine: RSVPEngine(), isVisible: true)
        Spacer()
    }
    .frame(height: 400)
    .background(Color.black)
}
