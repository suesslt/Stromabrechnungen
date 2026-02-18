import Foundation
import SwiftData

@Model
final class Stromrechnung {
    var rechnungssteller: String
    var abrechnungszeitraumVon: Date
    var abrechnungszeitraumBis: Date
    var rechnungsdatum: Date
    var rechnungsbetrag: Decimal
    var strombezugsmenge: Decimal

    var stromgemeinschaft: Stromgemeinschaft?

    init(
        rechnungssteller: String,
        abrechnungszeitraumVon: Date,
        abrechnungszeitraumBis: Date,
        rechnungsdatum: Date,
        rechnungsbetrag: Decimal,
        strombezugsmenge: Decimal,
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.rechnungssteller = rechnungssteller
        self.abrechnungszeitraumVon = abrechnungszeitraumVon
        self.abrechnungszeitraumBis = abrechnungszeitraumBis
        self.rechnungsdatum = rechnungsdatum
        self.rechnungsbetrag = rechnungsbetrag
        self.strombezugsmenge = strombezugsmenge
        self.stromgemeinschaft = stromgemeinschaft
    }
}
