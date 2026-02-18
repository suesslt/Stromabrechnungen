import Foundation
import SwiftData

@Model
final class Parteienabrechnung {
    var anteiliger_betrag: Decimal
    var anteilige_bezugsmenge: Decimal

    var stromabrechnung: Stromabrechnung?
    var bezugspartei: Bezugspartei?

    init(
        anteiliger_betrag: Decimal,
        anteilige_bezugsmenge: Decimal,
        stromabrechnung: Stromabrechnung? = nil,
        bezugspartei: Bezugspartei? = nil
    ) {
        self.anteiliger_betrag = anteiliger_betrag
        self.anteilige_bezugsmenge = anteilige_bezugsmenge
        self.stromabrechnung = stromabrechnung
        self.bezugspartei = bezugspartei
    }
}
