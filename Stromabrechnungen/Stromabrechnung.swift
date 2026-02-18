import Foundation
import SwiftData

@Model
final class Stromabrechnung {
    var datum: Date = Date.distantPast
    var abrechnungszeitraumVon: Date = Date.distantPast
    var abrechnungszeitraumBis: Date = Date.distantPast
    var abrechnungsbetrag: Decimal = 0
    var abrechnungsbezugsmenge: Decimal = 0

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.stromabrechnung)
    var parteienabrechungen: [Parteienabrechnung]?

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
