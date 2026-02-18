import Foundation
import SwiftData

@Model
final class Stromabrechnung {
    var abrechnungsdatum: Date
    var abrechnungsbetrag: Decimal
    var abrechnungsbezugsmenge: Decimal

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.stromabrechnung)
    var parteienabrechnung: [Parteienabrechnung] = []

    init(
        abrechnungsdatum: Date,
        abrechnungsbetrag: Decimal,
        abrechnungsbezugsmenge: Decimal,
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.abrechnungsdatum = abrechnungsdatum
        self.abrechnungsbetrag = abrechnungsbetrag
        self.abrechnungsbezugsmenge = abrechnungsbezugsmenge
        self.stromgemeinschaft = stromgemeinschaft
    }
}
