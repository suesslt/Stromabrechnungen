import Foundation
import SwiftData

@Model
final class Bezugspartei {
    var name: String = ""
    var anteil: Decimal = 0 // Anteil in Prozent (0–100). Die Summe aller Anteile einer Stromgemeinschaft muss 100 ergeben.
    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.bezugspartei)
    var parteienabrechungen: [Parteienabrechnung]?

    @Relationship(deleteRule: .cascade, inverse: \Parteienrechnung.bezugspartei)
    var parteienrechnungen: [Parteienrechnung]?

    init(name: String, anteil: Decimal, stromgemeinschaft: Stromgemeinschaft? = nil) {
        self.name = name
        self.anteil = anteil
        self.stromgemeinschaft = stromgemeinschaft
    }
}
