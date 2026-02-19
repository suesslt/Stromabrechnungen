import Foundation
import SwiftData

@Model
final class Parteienrechnung {
    var rechnungsdatum: Date = Date.now
    var rechnungszeitraumVon: Date = Date.distantPast
    var rechnungszeitraumBis: Date = Date.distantPast
    var abgerechneteBezugsmenge: Decimal = 0
    var abgerechneterBetrag: Decimal = 0
    var rechnungsstatus: Rechnungsstatus = Rechnungsstatus.offen

    var bezugspartei: Bezugspartei?

    init(
        rechnungsdatum: Date = .now,
        rechnungszeitraumVon: Date,
        rechnungszeitraumBis: Date,
        abgerechneteBezugsmenge: Decimal,
        abgerechneterBetrag: Decimal,
        rechnungsstatus: Rechnungsstatus = .offen,
        bezugspartei: Bezugspartei? = nil
    ) {
        self.rechnungsdatum = rechnungsdatum
        self.rechnungszeitraumVon = rechnungszeitraumVon
        self.rechnungszeitraumBis = rechnungszeitraumBis
        self.abgerechneteBezugsmenge = abgerechneteBezugsmenge
        self.abgerechneterBetrag = abgerechneterBetrag
        self.rechnungsstatus = rechnungsstatus
        self.bezugspartei = bezugspartei
    }
}
