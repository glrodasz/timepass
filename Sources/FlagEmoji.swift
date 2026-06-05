import Foundation

enum FlagEmoji {
    static func from(isoCode: String) -> String {
        let code = isoCode.uppercased()
        guard code.count == 2,
              code.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return "🌐"
        }
        let base: UInt32 = 0x1F1E6 - 65
        var scalars = String.UnicodeScalarView()
        for ch in code.unicodeScalars {
            guard let scalar = Unicode.Scalar(base + ch.value) else { return "🌐" }
            scalars.append(scalar)
        }
        return String(scalars)
    }
}
