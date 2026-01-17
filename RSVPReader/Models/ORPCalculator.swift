import Foundation

/// Calculates the Optimal Recognition Point (ORP) for a word
/// The ORP is the letter the eye should focus on for fastest recognition
struct ORPCalculator {
    
    /// ORP calculation mode
    enum Mode: String, CaseIterable, Identifiable {
        case spritz = "Spritz (Recommended)"
        case center = "Center Letter"
        case firstVowel = "First Vowel"
        
        var id: String { rawValue }
    }
    
    /// Calculate the ORP index for a given word
    /// - Parameters:
    ///   - word: The word to calculate ORP for
    ///   - mode: The calculation mode to use
    /// - Returns: The 0-based index of the ORP letter
    static func orpIndex(for word: String, mode: Mode = .spritz) -> Int {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
        guard !cleanWord.isEmpty else { return 0 }
        
        let length = cleanWord.count
        
        switch mode {
        case .spritz:
            return spritzORP(length: length)
        case .center:
            return length / 2
        case .firstVowel:
            return firstVowelIndex(in: cleanWord) ?? spritzORP(length: length)
        }
    }
    
    /// Spritz-style ORP calculation
    /// Based on word length, positions the focus point for optimal reading
    private static func spritzORP(length: Int) -> Int {
        switch length {
        case 1:
            return 0
        case 2...5:
            return 1 // 2nd letter (index 1)
        case 6...9:
            return 2 // 3rd letter (index 2)
        case 10...13:
            return 3 // 4th letter (index 3)
        default:
            return 4 // 5th letter for very long words
        }
    }
    
    /// Find the first vowel in a word
    private static func firstVowelIndex(in word: String) -> Int? {
        let vowels = Set("aeiouAEIOU")
        for (index, char) in word.enumerated() {
            if vowels.contains(char) {
                return index
            }
        }
        return nil
    }
    
    /// Split a word into three parts: before ORP, ORP letter, after ORP
    /// - Parameters:
    ///   - word: The word to split
    ///   - mode: The ORP calculation mode
    /// - Returns: Tuple of (prefix, orp letter, suffix)
    static func splitWord(_ word: String, mode: Mode = .spritz) -> (prefix: String, orp: String, suffix: String) {
        guard !word.isEmpty else {
            return ("", "", "")
        }
        
        let orpIdx = orpIndex(for: word, mode: mode)
        let characters = Array(word)
        
        // Ensure index is within bounds
        let safeIndex = min(orpIdx, characters.count - 1)
        
        let prefix = String(characters[0..<safeIndex])
        let orp = String(characters[safeIndex])
        let suffix = safeIndex + 1 < characters.count ? String(characters[(safeIndex + 1)...]) : ""
        
        return (prefix, orp, suffix)
    }
}
