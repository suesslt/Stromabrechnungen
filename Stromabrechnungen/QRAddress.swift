//
//  QRAddress.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//


import Foundation

// MARK: - Datenstrukturen
struct QRAddress: Codable {
    var name: String
    var street: String
    var houseNumber: String
    var postalCode: String
    var city: String
    var countryCode: String // ISO 3166-1 (z.B. "CH")

    /// Leere Adresse als sicherer Ausgangszustand
    static let empty = QRAddress(
        name: "",
        street: "",
        houseNumber: "",
        postalCode: "",
        city: "",
        countryCode: "CH"
    )
}

// MARK: - AppStorage-Kompatibilität
extension QRAddress: RawRepresentable {

    // Interner Hilfstyp – nur Codable, kein RawRepresentable
    // Bricht die Rekursion, da JSONEncoder hier nie rawValue aufruft
    private struct Storage: Codable {
        var name: String
        var street: String
        var houseNumber: String
        var postalCode: String
        var city: String
        var countryCode: String
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let storage = try? Self.decoder.decode(Storage.self, from: data)
        else { return nil }
        self = QRAddress(
            name: storage.name,
            street: storage.street,
            houseNumber: storage.houseNumber,
            postalCode: storage.postalCode,
            city: storage.city,
            countryCode: storage.countryCode
        )
    }

    public var rawValue: String {
        let storage = Storage(
            name: name,
            street: street,
            houseNumber: houseNumber,
            postalCode: postalCode,
            city: city,
            countryCode: countryCode
        )
        do {
            let data = try Self.encoder.encode(storage)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            assertionFailure("QRAddress encoding failed: \(error)")
            return "{}"
        }
    }
}

enum QRReferenceType: String {
    case qrReference = "QRR"   // Für QR-IBAN
    case creditorRef = "SCOR"  // ISO 11649
    case none = "NON"          // Ohne Referenz
}

struct QRBill {
    let iban: String
    let creditor: QRAddress
    let amount: Double?
    let currency: String // "CHF" oder "EUR"
    let debtor: QRAddress?
    let referenceType: QRReferenceType
    let reference: String?
    let additionalInfo: String?

    // MARK: - Factory aus SwiftData-Modellen

    /// Erstellt einen QRBill direkt aus einer Parteienrechnung.
    /// - Parameters:
    ///   - rechnung: Die Parteienrechnung (enthält Betrag & Bezugspartei)
    ///   - creditor: Stammdaten-Adresse (z.B. aus @AppStorage gespeichert)
    ///   - additionalInfo: Optionaler Zusatztext auf der Rechnung (z.B. "Stromabrechnung Jan–Feb")
    static func fromParteienrechnung(
        _ rechnung: Parteienrechnung,
        creditor: QRAddress,
        additionalInfo: String? = nil
    ) -> QRBill? {
        guard
            let bezugspartei = rechnung.bezugspartei,
            let gemeinschaft = bezugspartei.stromgemeinschaft
        else { return nil }

        let debtor = QRAddress(
            name: bezugspartei.name,
            street: bezugspartei.street,
            houseNumber: bezugspartei.houseNumber,
            postalCode: bezugspartei.postalCode,
            city: bezugspartei.city,
            countryCode: bezugspartei.countryCode
        )

        return QRBill(
            iban: gemeinschaft.abrechnungskonto.replacingOccurrences(of: " ", with: ""),
            creditor: creditor,
            amount: Double(truncating: rechnung.abgerechneterBetrag as NSDecimalNumber),
            currency: "CHF",
            debtor: debtor,
            referenceType: .none,
            reference: nil,
            additionalInfo: additionalInfo
        )
    }

    /// Erstellt einen QRBill direkt aus einer Parteienabrechnung.
    /// - Parameters:
    ///   - parteienabrechnung: Die abgerechnete Parteienabrechnung (enthält Betrag & Bezugspartei)
    ///   - creditor: Stammdaten-Adresse (z.B. aus @AppStorage gespeichert)
    ///   - additionalInfo: Optionaler Zusatztext auf der Rechnung (z.B. "Rechnung Nr. 42")
    static func fromParteienabrechnung(
        _ parteienabrechnung: Parteienabrechnung,
        creditor: QRAddress,
        additionalInfo: String? = nil
    ) -> QRBill? {
        guard
            let gemeinschaft = parteienabrechnung.stromabrechnung?.stromgemeinschaft,
            let bezugspartei = parteienabrechnung.bezugspartei
        else { return nil }

        let debtor = QRAddress(
            name: bezugspartei.name,
            street: bezugspartei.street,
            houseNumber: bezugspartei.houseNumber,
            postalCode: bezugspartei.postalCode,
            city: bezugspartei.city,
            countryCode: bezugspartei.countryCode
        )

        return QRBill(
            iban: gemeinschaft.abrechnungskonto.replacingOccurrences(of: " ", with: ""),
            creditor: creditor,
            amount: Double(truncating: parteienabrechnung.betrag as NSDecimalNumber),
            currency: "CHF",
            debtor: debtor,
            referenceType: .none,
            reference: nil,
            additionalInfo: additionalInfo
        )
    }
    
    // MARK: - Algorithmus zur Payload-Generierung
    func generatePayload() -> String {
        var lines: [String] = []
        
        // 1. Header
        lines.append("SPC")      // QR-Type
        lines.append("0200")     // Version (0200 entspricht V2.x)
        lines.append("1")        // Coding (UTF-8)
        
        // 2. Creditor Info (IBAN & Adresse Typ S) → Zeilen 4–11
        lines.append(iban.replacingOccurrences(of: " ", with: ""))
        lines.append(contentsOf: formatAddress(creditor))
        
        // 3. Ultimate Creditor → Zeilen 12–18 (im Standard reserviert, immer leer)
        lines.append(contentsOf: Array(repeating: "", count: 7))
        
        // 4. Amount & Currency → Zeilen 19–20
        if let amt = amount {
            lines.append(String(format: "%.2f", amt))
        } else {
            lines.append("") // Optionaler Betrag
        }
        lines.append(currency)
        
        // 5. Debtor Info → Zeilen 21–27
        if let debtor = debtor {
            lines.append(contentsOf: formatAddress(debtor))
        } else {
            // 7 leere Zeilen für fehlenden Debtor
            lines.append(contentsOf: Array(repeating: "", count: 7))
        }
        
        // 6. Payment Reference
        lines.append(referenceType.rawValue)
        lines.append(reference?.replacingOccurrences(of: " ", with: "") ?? "")
        
        // 7. Additional Info
        lines.append(additionalInfo ?? "")
        lines.append("EPD") // Trailer
        
        // 8. Alternative Verfahren (max 2, hier leer)
        lines.append("")
        lines.append("")
        
        return lines.joined(separator: "\n")
    }
    
    private func formatAddress(_ addr: QRAddress) -> [String] {
        return [
            "S",                // Adresstyp "S" (Strukturiert)
            addr.name,
            addr.street,
            addr.houseNumber,
            addr.postalCode,
            addr.city,
            addr.countryCode
        ]
    }
}

// MARK: - Beispiel & Testdaten
let myAddress = QRAddress(
    name: "Muster AG",
    street: "Bahnhofstrasse",
    houseNumber: "1",
    postalCode: "8001",
    city: "Zürich",
    countryCode: "CH"
)

let customerAddress = QRAddress(
    name: "Hans Mustermann",
    street: "Rebenweg",
    houseNumber: "12",
    postalCode: "3000",
    city: "Bern",
    countryCode: "CH"
)

let bill = QRBill(
    iban: "CH12 3000 0000 0000 1234 5", // Beispiel QR-IBAN
    creditor: myAddress,
    amount: 150.75,
    currency: "CHF",
    debtor: customerAddress,
    referenceType: .qrReference,
    reference: "21 00000 00003 13947 14300 09017",
    additionalInfo: "Rechnung Nr. 10234"
)
