//
//  IBANValidator.swift
//  Stromabrechnungen
//

import Foundation

/// IBAN-Validierung gemäss ISO 13616 / ISO 7064 (Mod-97-Prüfung).
enum IBANValidator {

    /// Prüft ob eine IBAN syntaktisch gültig ist (Länge + Mod-97-Prüfziffer).
    static func isValid(_ iban: String) -> Bool {
        let clean = iban.replacingOccurrences(of: " ", with: "").uppercased()
        // ISO 13616: Mindestlänge 5, Maximallänge 34
        guard clean.count >= 5, clean.count <= 34 else { return false }
        // Nur Buchstaben und Ziffern erlaubt
        guard clean.allSatisfy({ $0.isLetter || $0.isNumber }) else { return false }
        // Erste 2 Zeichen müssen Buchstaben sein (Ländercode)
        guard clean.prefix(2).allSatisfy({ $0.isLetter }) else { return false }
        // Zeichen 3–4 müssen Ziffern sein (Prüfziffer)
        guard clean.dropFirst(2).prefix(2).allSatisfy({ $0.isNumber }) else { return false }
        // Mod-97-Prüfung (ISO 7064)
        let rearranged = String(clean.dropFirst(4)) + String(clean.prefix(4))
        let numeric = rearranged.map { char -> String in
            if let digit = char.wholeNumberValue {
                return String(digit)
            }
            // A=10, B=11, …, Z=35
            return String(Int(char.asciiValue!) - 55)
        }.joined()
        return mod97(numeric) == 1
    }

    /// Validierungsmeldung für die UI. Gibt `nil` zurück wenn gültig oder leer.
    static func validationMessage(_ iban: String) -> String? {
        let clean = iban.replacingOccurrences(of: " ", with: "")
        if clean.isEmpty { return nil }
        if !isValid(iban) { return "Ungültige IBAN" }
        return nil
    }

    // MARK: - Private

    private static func mod97(_ numericString: String) -> Int {
        var remainder = 0
        for char in numericString {
            remainder = (remainder * 10 + Int(String(char))!) % 97
        }
        return remainder
    }
}
