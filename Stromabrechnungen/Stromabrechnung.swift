import Foundation
import SwiftData

@Model
final class Stromabrechnung {
    var datum: Date
    var abrechnungszeitraumVon: Date
    var abrechnungszeitraumBis: Date
    var abrechnungsbetrag: Decimal
    var abrechnungsbezugsmenge: Decimal

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.stromabrechnung)
    var parteienabrechungen: [Parteienabrechnung] = []

    init(
        datum: Date = .now,
        abrechnungszeitraumVon: Date,
        abrechnungszeitraumBis: Date,
        abrechnungsbetrag: Decimal,
        abrechnungsbezugsmenge: Decimal,
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.datum = datum
        self.abrechnungszeitraumVon = abrechnungszeitraumVon
        self.abrechnungszeitraumBis = abrechnungszeitraumBis
        self.abrechnungsbetrag = abrechnungsbetrag
        self.abrechnungsbezugsmenge = abrechnungsbezugsmenge
        self.stromgemeinschaft = stromgemeinschaft
    }
}
