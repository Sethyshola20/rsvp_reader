import SwiftUI
import AppKit

/// The main content view - a single-screen RSVP reader
struct ContentView: View {
    @StateObject private var engine = RSVPEngine()
    @State private var showingFileImporter = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var fileName: String = ""
    @State private var showSidebar: Bool = true
    @State private var showTextReader: Bool = false
    
    @AppStorage("orpMode") private var orpMode: ORPCalculator.Mode = .spritz
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if engine.hasContent {
                // Main reading view with sidebar
                HStack(spacing: 0) {
                    // Paragraph sidebar (toggleable)
                    ParagraphSidebarView(engine: engine, isVisible: showSidebar)
                    
                    // Divider
                    if showSidebar {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1)
                    }
                    
                    // Reading area
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Word display
                        WordDisplayView(
                            word: engine.currentWord,
                            orpMode: orpMode
                        )
                        
                        Spacer()
                        
                        // Bottom info bar
                        BottomBarView(
                            engine: engine,
                            fileName: fileName,
                            showSidebar: $showSidebar,
                            showTextReader: $showTextReader
                        )
                    }
                }
                
                // Text reader overlay
                if showTextReader {
                    TextReaderView(
                        engine: engine,
                        isVisible: $showTextReader,
                        onWordSelected: { wordIndex in
                            engine.goToWord(at: wordIndex)
                            showTextReader = false
                        }
                    )
                    .transition(.opacity)
                }
            } else {
                // Empty state - drop zone
                DropZoneView(
                    onOpenFile: { showingFileImporter = true },
                    onPasteText: { text in
                        engine.loadText(text)
                        fileName = "Pasted Text"
                    }
                )
            }
        }
        .frame(minWidth: 700, minHeight: 400)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.plainText, .pdf, .init(filenameExtension: "md")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }
    
    // MARK: - File Handling
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadFile(url)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    loadFile(url)
                }
            }
        }
        return true
    }
    
    private func loadFile(_ url: URL) {
        // Start security-scoped access
        guard url.startAccessingSecurityScopedResource() else {
            showError("Cannot access file")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let text = try FileLoader.loadText(from: url)
            engine.loadText(text)
            fileName = url.lastPathComponent
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    // MARK: - Keyboard Controls
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        switch keyPress.key {
        case .space:
            if !showTextReader {
                engine.togglePlayPause()
            }
            return .handled
            
        case .leftArrow:
            if showTextReader { return .ignored }
            if keyPress.modifiers.contains(.command) {
                engine.restart()
            } else if keyPress.modifiers.contains(.option) {
                engine.previousParagraph()
            } else {
                engine.skipBackward()
            }
            return .handled
            
        case .rightArrow:
            if showTextReader { return .ignored }
            if keyPress.modifiers.contains(.option) {
                engine.nextParagraph()
            } else {
                engine.skipForward()
            }
            return .handled
            
        case .upArrow:
            if !showTextReader {
                engine.increaseSpeed()
            }
            return .handled
            
        case .downArrow:
            if !showTextReader {
                engine.decreaseSpeed()
            }
            return .handled
            
        case "o" where keyPress.modifiers.contains(.command):
            showingFileImporter = true
            return .handled
            
        case "v" where keyPress.modifiers.contains(.command):
            // Paste from clipboard if no content loaded
            if !engine.hasContent {
                if let clipboard = NSPasteboard.general.string(forType: .string),
                   !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    engine.loadText(clipboard)
                    fileName = "Pasted Text"
                }
            }
            return .handled
            
        case "s" where keyPress.modifiers.contains(.command):
            showSidebar.toggle()
            return .handled
            
        case "r" where keyPress.modifiers.contains(.command):
            if engine.hasContent {
                showTextReader.toggle()
            }
            return .handled
            
        case .escape:
            if showTextReader {
                showTextReader = false
            } else {
                engine.closeFile()
                fileName = ""
            }
            return .handled
            
        default:
            return .ignored
        }
    }
}
