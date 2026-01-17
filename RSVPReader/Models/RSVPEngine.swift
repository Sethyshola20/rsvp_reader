import Foundation
import Combine

/// Represents a paragraph with its content and word range
struct Paragraph: Identifiable {
    let id: Int
    let text: String
    let preview: String
    let wordRange: Range<Int>
    
    init(id: Int, text: String, wordRange: Range<Int>) {
        self.id = id
        self.text = text
        self.wordRange = wordRange
        // Create a preview (first ~50 chars)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 50 {
            self.preview = String(trimmed.prefix(50)) + "..."
        } else {
            self.preview = trimmed
        }
    }
}

/// Core RSVP engine that handles word display timing and navigation
@MainActor
class RSVPEngine: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var currentWord: String = ""
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var paragraphs: [Paragraph] = []
    @Published private(set) var currentParagraphIndex: Int = 0
    @Published var wordsPerMinute: Int = 300 {
        didSet {
            // Clamp WPM to reasonable range (only if needed to avoid infinite loop)
            let clamped = max(100, min(1000, wordsPerMinute))
            if wordsPerMinute != clamped {
                wordsPerMinute = clamped
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var words: [String] = []
    private var timer: Timer?
    
    /// Interval between words in seconds
    private var wordInterval: TimeInterval {
        60.0 / Double(wordsPerMinute)
    }
    
    // MARK: - Public Interface
    
    /// Load text content and prepare for reading
    func loadText(_ text: String) {
        // Split into paragraphs first
        let paragraphTexts = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Build words array and paragraph metadata
        words = []
        paragraphs = []
        
        for (index, paragraphText) in paragraphTexts.enumerated() {
            let paragraphWords = paragraphText.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            if !paragraphWords.isEmpty {
                let startIndex = words.count
                words.append(contentsOf: paragraphWords)
                let endIndex = words.count
                
                let paragraph = Paragraph(
                    id: index,
                    text: paragraphText,
                    wordRange: startIndex..<endIndex
                )
                paragraphs.append(paragraph)
            }
        }
        
        currentIndex = 0
        currentParagraphIndex = 0
        updateCurrentWord()
        updateProgress()
    }
    
    /// Total word count
    var totalWords: Int {
        words.count
    }
    
    /// Check if content is loaded
    var hasContent: Bool {
        !words.isEmpty
    }
    
    // MARK: - Playback Controls
    
    func play() {
        guard hasContent, !isPlaying else { return }
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        isPlaying = false
        stopTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func restart() {
        pause()
        currentIndex = 0
        currentParagraphIndex = 0
        updateCurrentWord()
        updateProgress()
    }
    
    /// Close current file and return to empty state
    func closeFile() {
        pause()
        words = []
        paragraphs = []
        currentWord = ""
        currentIndex = 0
        currentParagraphIndex = 0
        progress = 0
    }
    
    // MARK: - Navigation
    
    func skipForward(words count: Int = 10) {
        currentIndex = min(currentIndex + count, words.count - 1)
        updateCurrentWord()
        updateProgress()
        updateCurrentParagraph()
    }
    
    func skipBackward(words count: Int = 10) {
        currentIndex = max(currentIndex - count, 0)
        updateCurrentWord()
        updateProgress()
        updateCurrentParagraph()
    }
    
    func goToWord(at index: Int) {
        currentIndex = max(0, min(index, words.count - 1))
        updateCurrentWord()
        updateProgress()
        updateCurrentParagraph()
    }
    
    /// Jump to a specific paragraph
    func goToParagraph(_ paragraph: Paragraph) {
        pause()
        currentIndex = paragraph.wordRange.lowerBound
        updateCurrentWord()
        updateProgress()
        updateCurrentParagraph()
    }
    
    /// Jump to next paragraph
    func nextParagraph() {
        guard currentParagraphIndex < paragraphs.count - 1 else { return }
        goToParagraph(paragraphs[currentParagraphIndex + 1])
    }
    
    /// Jump to previous paragraph
    func previousParagraph() {
        guard currentParagraphIndex > 0 else { return }
        goToParagraph(paragraphs[currentParagraphIndex - 1])
    }
    
    // MARK: - WPM Adjustment
    
    func increaseSpeed(by amount: Int = 25) {
        wordsPerMinute += amount
        if isPlaying {
            restartTimer()
        }
    }
    
    func decreaseSpeed(by amount: Int = 25) {
        wordsPerMinute -= amount
        if isPlaying {
            restartTimer()
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: wordInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceWord()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func restartTimer() {
        stopTimer()
        if isPlaying {
            startTimer()
        }
    }
    
    private func advanceWord() {
        if currentIndex < words.count - 1 {
            currentIndex += 1
            updateCurrentWord()
            updateProgress()
            updateCurrentParagraph()
        } else {
            // Reached end
            pause()
        }
    }
    
    private func updateCurrentWord() {
        if words.indices.contains(currentIndex) {
            currentWord = words[currentIndex]
        } else {
            currentWord = ""
        }
    }
    
    private func updateProgress() {
        guard !words.isEmpty else {
            progress = 0
            return
        }
        progress = Double(currentIndex) / Double(words.count - 1)
    }
    
    private func updateCurrentParagraph() {
        for (index, paragraph) in paragraphs.enumerated() {
            if paragraph.wordRange.contains(currentIndex) {
                currentParagraphIndex = index
                return
            }
        }
    }
}
