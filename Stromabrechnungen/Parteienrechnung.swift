import Foundation
import SwiftData
import SwissInvoice

@Model
final class Parteienrechnung {
    var rechnungsdatum: Date = Date.now
    var rechnungszeitraumVon: Date = Date.distantPast
    var rechnungszeitraumBis: Date = Date.distantPast
    var abgerechneteBezugsmenge: Decimal = 0
    var abgerechneterBetrag: Decimal = 0
    var rechnungsstatus: Rechnungsstatus = Rechnungsstatus.offen

    var bezugspartei: Bezugspartei?

    init(
        rechnungsdatum: Date = .now,
        rechnungszeitraumVon: Date,
        rechnungszeitraumBis: Date,
        abgerechneteBezugsmenge: Decimal,
        abgerechneterBetrag: Decimal,
        rechnungsstatus: Rechnungsstatus = .offen,
        bezugspartei: Bezugspartei? = nil
    ) {
        self.rechnungsdatum = rechnungsdatum
        self.rechnungszeitraumVon = rechnungszeitraumVon
        self.rechnungszeitraumBis = rechnungszeitraumBis
        self.abgerechneteBezugsmenge = abgerechneteBezugsmenge
        self.abgerechneterBetrag = abgerechneterBetrag
        self.rechnungsstatus = rechnungsstatus
        self.bezugspartei = bezugspartei
    }

    // MARK: - SwissInvoice-Konvertierung

    /// Erstellt eine SwissInvoice aus dieser Parteienrechnung.
    /// Die Kreditor-Adresse wird aus den Stammdaten der Stromgemeinschaft gelesen.
    /// - Returns: SwissInvoice oder nil, falls Bezugspartei/Stromgemeinschaft fehlt
    func swissInvoice() -> SwissInvoice? {
        guard
            let bezugspartei,
            let gemeinschaft = bezugspartei.stromgemeinschaft
        else { return nil }

        let creditor = gemeinschaft.kreditorAdresse
        let debtor = bezugspartei.address
        let iban = gemeinschaft.abrechnungskonto.replacingOccurrences(of: " ", with: "")

        let preisProKwh: Decimal = abgerechneteBezugsmenge > 0
            ? abgerechneterBetrag / abgerechneteBezugsmenge
            : 0

        let lineItem = InvoiceLineItem(
            lineItemType: .unitPrice,
            description: "Strombezug",
            quantity: abgerechneteBezugsmenge,
            unit: "kWh",
            unitPrice: Money(amount: preisProKwh, currency: .chf),
            amount: Money(amount: abgerechneterBetrag, currency: .chf)
        )

        let von = rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)
        let bis = rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted)

        let betragFormatiert = Money(amount: abgerechneterBetrag, currency: .chf).formatted

        let leadingText = resolvePlaceholders(
            gemeinschaft.rechnungLeadingText,
            name: bezugspartei.name,
            von: von,
            bis: bis,
            betrag: betragFormatiert,
            menge: "\(abgerechneteBezugsmenge.formatted()) kWh",
            datum: rechnungsdatum.formatted(date: .abbreviated, time: .omitted),
            iban: gemeinschaft.abrechnungskonto
        )

        let trailingText = resolvePlaceholders(
            gemeinschaft.rechnungTrailingText,
            name: bezugspartei.name,
            von: von,
            bis: bis,
            betrag: betragFormatiert,
            menge: "\(abgerechneteBezugsmenge.formatted()) kWh",
            datum: rechnungsdatum.formatted(date: .abbreviated, time: .omitted),
            iban: gemeinschaft.abrechnungskonto
        )

        return SwissInvoice(
            title: "Stromrechnung",
            creditor: creditor,
            debtor: debtor,
            invoiceDate: rechnungsdatum,
            iban: iban,
            subject: "Stromabrechnung \(von) – \(bis)",
            leadingText: leadingText,
            lineItems: [lineItem],
            trailingText: trailingText
        )
    }

    // MARK: - Platzhalter-Auflösung

    /// Ersetzt Platzhalter in einem Template-String mit konkreten Rechnungswerten.
    /// Gibt `nil` zurück wenn das Template leer ist.
    private func resolvePlaceholders(
        _ template: String,
        name: String,
        von: String,
        bis: String,
        betrag: String,
        menge: String,
        datum: String,
        iban: String
    ) -> String? {
        guard !template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        return template
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{zeitraumVon}", with: von)
            .replacingOccurrences(of: "{zeitraumBis}", with: bis)
            .replacingOccurrences(of: "{betrag}", with: betrag)
            .replacingOccurrences(of: "{menge}", with: menge)
            .replacingOccurrences(of: "{rechnungsdatum}", with: datum)
            .replacingOccurrences(of: "{iban}", with: iban)
    }
}
