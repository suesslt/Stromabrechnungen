import Foundation
import SwiftData

@Model
final class Parteienabrechnung {
    var betrag: Decimal
    var bezugsmenge: Decimal

    var stromabrechnung: Stromabrechnung?
    var bezugspartei: Bezugspartei?

    init(
        betrag: Decimal,
        bezugsmenge: Decimal,
        stromabrechnung: Stromabrechnung? = nil,
        bezugspartei: Bezugspartei? = nil
    ) {
        self.betrag = betrag
        self.bezugsmenge = bezugsmenge
        self.stromabrechnung = stromabrechnung
        self.bezugspartei = bezugspartei
    }
}
