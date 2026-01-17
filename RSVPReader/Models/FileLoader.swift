import Foundation
import PDFKit

/// Handles loading and parsing different file formats
struct FileLoader {
    
    enum FileError: LocalizedError {
        case unsupportedFormat
        case unableToRead
        case emptyContent
        case pdfExtractionFailed
        
        var errorDescription: String? {
            switch self {
            case .unsupportedFormat:
                return "Unsupported file format. Please use .txt, .md, or .pdf files."
            case .unableToRead:
                return "Unable to read the file."
            case .emptyContent:
                return "The file appears to be empty."
            case .pdfExtractionFailed:
                return "Could not extract text from PDF."
            }
        }
    }
    
    /// Supported file extensions
    static let supportedExtensions = ["txt", "md", "pdf"]
    
    /// Load text content from a file URL
    static func loadText(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()
        
        guard supportedExtensions.contains(ext) else {
            throw FileError.unsupportedFormat
        }
        
        let text: String
        
        switch ext {
        case "pdf":
            text = try loadPDF(from: url)
        case "md":
            text = try loadMarkdown(from: url)
        default: // txt
            text = try loadPlainText(from: url)
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FileError.emptyContent
        }
        
        return text
    }
    
    // MARK: - Private Loaders
    
    private static func loadPlainText(from url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw FileError.unableToRead
        }
    }
    
    private static func loadMarkdown(from url: URL) throws -> String {
        let content = try loadPlainText(from: url)
        return stripMarkdown(content)
    }
    
    private static func loadPDF(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileError.unableToRead
        }
        
        var text = ""
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex),
               let pageText = page.string {
                text += pageText + "\n\n"
            }
        }
        
        guard !text.isEmpty else {
            throw FileError.pdfExtractionFailed
        }
        
        // Normalize PDF text (fix common extraction issues)
        return normalizePDFText(text)
    }
    
    /// Normalize text extracted from PDFs to fix common spacing issues
    private static func normalizePDFText(_ text: String) -> String {
        var result = text
        
        // 1. Replace multiple spaces with single space
        result = result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        
        // 2. Replace multiple tabs with single space
        result = result.replacingOccurrences(of: #"\t+"#, with: " ", options: .regularExpression)
        
        // 3. Fix hyphenated words at line breaks (word-\nword -> wordword)
        result = result.replacingOccurrences(of: #"-\s*\n\s*"#, with: "", options: .regularExpression)
        
        // 4. Replace single line breaks (within paragraphs) with space
        // But preserve double line breaks (paragraph separators)
        result = result.replacingOccurrences(of: #"(?<!\n)\n(?!\n)"#, with: " ", options: .regularExpression)
        
        // 5. Normalize multiple line breaks to double (paragraph separator)
        result = result.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        
        // 6. Clean up spaces around line breaks
        result = result.replacingOccurrences(of: #" +\n"#, with: "\n", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\n +"#, with: "\n", options: .regularExpression)
        
        // 7. Replace multiple spaces again (after other transformations)
        result = result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        
        // 8. Remove space before punctuation
        result = result.replacingOccurrences(of: #" +([.,;:!?])"#, with: "$1", options: .regularExpression)
        
        // 9. Ensure space after punctuation (if followed by letter)
        result = result.replacingOccurrences(of: #"([.,;:!?])([A-Za-z])"#, with: "$1 $2", options: .regularExpression)
        
        // 10. Trim leading/trailing whitespace from each line
        let lines = result.components(separatedBy: "\n")
        result = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Strip common markdown syntax for cleaner reading
    private static func stripMarkdown(_ text: String) -> String {
        var result = text
        
        // Remove headers
        result = result.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        
        // Remove bold/italic markers
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"__(.+?)__"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"_(.+?)_"#, with: "$1", options: .regularExpression)
        
        // Remove links, keep text
        result = result.replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression)
        
        // Remove code blocks
        result = result.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"`(.+?)`"#, with: "$1", options: .regularExpression)
        
        // Remove bullet points
        result = result.replacingOccurrences(of: #"^\s*[-*+]\s+"#, with: "", options: .regularExpression)
        
        // Remove horizontal rules
        result = result.replacingOccurrences(of: #"^[-*_]{3,}\s*$"#, with: "", options: .regularExpression)
        
        return result
    }
}
