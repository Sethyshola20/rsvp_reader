import SwiftUI
import AppKit

/// Empty state view with file drop zone
struct DropZoneView: View {
    let onOpenFile: () -> Void
    let onPasteText: (String) -> Void
    
    @State private var isHovering = false
    @State private var isHoveringPaste = false
    @State private var showPasteSheet = false
    @State private var pastedText = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "doc.text")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.white.opacity(0.5))
            
            // Instructions
            VStack(spacing: 8) {
                Text("Drop a file to start reading")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Supports .txt, .md, and .pdf")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Buttons row
            HStack(spacing: 16) {
                // Open file button
                Button(action: onOpenFile) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open File")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isHovering ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
                    .foregroundColor(.white.opacity(0.8))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                // Paste text button
                Button(action: { showPasteSheet = true }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste Text")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isHoveringPaste ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
                    .foregroundColor(.white.opacity(0.8))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringPaste = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            
            // Keyboard hints
            HStack(spacing: 16) {
                Text("⌘O Open")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                Text("⌘V Paste")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showPasteSheet) {
            PasteTextSheet(
                text: $pastedText,
                onSubmit: {
                    if !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onPasteText(pastedText)
                        pastedText = ""
                    }
                    showPasteSheet = false
                },
                onCancel: {
                    pastedText = ""
                    showPasteSheet = false
                }
            )
        }
    }
}

/// Sheet for pasting text directly
struct PasteTextSheet: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Paste Text")
                    .font(.headline)
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.escape)
            }
            .padding(.bottom, 8)
            
            // Text editor
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .border(Color.gray.opacity(0.3), width: 1)
            
            // Instructions
            Text("Paste or type text here, then click Start Reading")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Actions
            HStack {
                Button("Paste from Clipboard") {
                    if let clipboard = NSPasteboard.general.string(forType: .string) {
                        text = clipboard
                    }
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Spacer()
                
                Button("Start Reading") { onSubmit() }
                    .keyboardShortcut(.return)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500, height: 350)
    }
}

#Preview {
    DropZoneView(onOpenFile: {}, onPasteText: { _ in })
        .background(Color.black)
}
