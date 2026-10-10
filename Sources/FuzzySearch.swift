import Foundation

/// Word-based, typo-tolerant matching for the time zone picker.
enum FuzzySearch {
    /// Lowercased, diacritic-free words. `_`, `/` and punctuation act as separators,
    /// so "America/New_York" becomes ["america", "new", "york"].
    static func words(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Every token starts some word.
    static func prefixesAll(_ tokens: [String], in words: [String]) -> Bool {
        tokens.allSatisfy { token in
            words.contains { $0.hasPrefix(token) }
        }
    }

    /// Every token appears inside some word, or is within a few typos of a word
    /// or of the start of a word the user is still typing.
    static func approximatelyMatchesAll(_ tokens: [String], in words: [String]) -> Bool {
        tokens.allSatisfy { token in
            let budget = typoBudget(for: token)
            return words.contains { word in
                word.contains(token)
                    || (budget > 0 && distance(token, word) <= budget)
                    || (budget > 0 && distance(token, String(word.prefix(token.count))) <= budget)
            }
        }
    }

    /// Each word plus every run of trailing words joined together, so
    /// ["america", "new", "york"] also matches "newyork".
    static func withJoinedRuns(_ words: [String]) -> [String] {
        words + words.indices.dropFirst().dropLast().map { words[$0...].joined() } + [words.joined()]
    }

    // Short tokens stay exact; otherwise "new" would match half the catalog.
    private static func typoBudget(for token: String) -> Int {
        switch token.count {
        case ..<4: return 0
        case ..<8: return 1
        default: return 2
        }
    }

    /// Optimal string alignment distance: insertions, deletions, substitutions
    /// and swaps of adjacent characters each cost one.
    static func distance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous2 = [Int](repeating: 0, count: b.count + 1)
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    current[j] = min(current[j], previous2[j - 2] + 1)
                }
            }
            (previous2, previous, current) = (previous, current, previous2)
        }
        return previous[b.count]
    }
}
