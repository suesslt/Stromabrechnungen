import Foundation
import SwiftData

@Model
final class Bezugspartei {
    var name: String = ""
    /// Anteil in Prozent (0–100). Die Summe aller Anteile einer Stromgemeinschaft muss 100 ergeben.
    var anteil: Decimal = 0

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.bezugspartei)
    var parteienabrechungen: [Parteienabrechnung]?

    init(name: String, anteil: Decimal, stromgemeinschaft: Stromgemeinschaft? = nil) {
        self.name = name
        self.anteil = anteil
        self.stromgemeinschaft = stromgemeinschaft
    }
}
