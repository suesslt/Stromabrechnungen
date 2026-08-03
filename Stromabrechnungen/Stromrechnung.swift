import Foundation
import SwiftData

@Model
final class Stromrechnung {
    var rechnungssteller: String = ""
    var abrechnungszeitraumVon: Date = Date.distantPast
    var abrechnungszeitraumBis: Date = Date.distantPast
    var rechnungsdatum: Date = Date.distantPast
    var rechnungsbetrag: Decimal = 0
    var gutschrift: Decimal = 0
    var strombezugsmenge: Decimal = 0

    var stromgemeinschaft: Stromgemeinschaft?

    /// Verrechenbarer Betrag = Rechnungsbetrag minus Gutschrift.
    /// Basis für die Verteilung an Bezugsparteien. Kann negativ sein,
    /// wenn die Gutschrift den Rechnungsbetrag übersteigt.
    var verrechenbarerBetrag: Decimal {
        rechnungsbetrag - gutschrift
    }

    init(
        rechnungssteller: String,
        abrechnungszeitraumVon: Date,
        abrechnungszeitraumBis: Date,
        rechnungsdatum: Date,
        rechnungsbetrag: Decimal,
        gutschrift: Decimal = 0,
        strombezugsmenge: Decimal,
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.rechnungssteller = rechnungssteller
        self.abrechnungszeitraumVon = abrechnungszeitraumVon
        self.abrechnungszeitraumBis = abrechnungszeitraumBis
        self.rechnungsdatum = rechnungsdatum
        self.rechnungsbetrag = rechnungsbetrag
        self.gutschrift = gutschrift
        self.strombezugsmenge = strombezugsmenge
        self.stromgemeinschaft = stromgemeinschaft
    }
}
