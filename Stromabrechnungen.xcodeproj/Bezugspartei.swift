import Foundation
import SwiftData

@Model
final class Bezugspartei {
    var bezeichnung: String
    /// Anteil in Prozent, z.B. 0.25 = 25%
    var anteil: Decimal

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .nullify, inverse: \Parteienabrechnung.bezugspartei)
    var parteienabrechnung: [Parteienabrechnung] = []

    init(
        bezeichnung: String,
        anteil: Decimal,
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.bezeichnung = bezeichnung
        self.anteil = anteil
        self.stromgemeinschaft = stromgemeinschaft
    }
}
