import Foundation
import SwiftData
import SwissInvoice

@Model
final class Bezugspartei {
    var name: String = ""
    var anteil: Decimal = 0 // Anteil in Prozent (0–100). Die Summe aller Anteile einer Stromgemeinschaft muss 100 ergeben.

    // MARK: - Adressfelder
    var street: String = ""
    var houseNumber: String = ""
    var postalCode: String = ""
    var city: String = ""
    var countryCode: String = "CH" // ISO 3166-1 (z.B. "CH")

    var stromgemeinschaft: Stromgemeinschaft?

    @Relationship(deleteRule: .cascade, inverse: \Parteienabrechnung.bezugspartei)
    var parteienabrechungen: [Parteienabrechnung]?

    @Relationship(deleteRule: .cascade, inverse: \Parteienrechnung.bezugspartei)
    var parteienrechnungen: [Parteienrechnung]?

    init(
        name: String,
        anteil: Decimal,
        street: String = "",
        houseNumber: String = "",
        postalCode: String = "",
        city: String = "",
        countryCode: String = "CH",
        stromgemeinschaft: Stromgemeinschaft? = nil
    ) {
        self.name = name
        self.anteil = anteil
        self.street = street
        self.houseNumber = houseNumber
        self.postalCode = postalCode
        self.city = city
        self.countryCode = countryCode
        self.stromgemeinschaft = stromgemeinschaft
    }

    // MARK: - Address-Konvertierung
    var address: Address {
        Address(
            name: name,
            addressAddition: "",
            street: street,
            houseNumber: houseNumber,
            postalCode: postalCode,
            city: city,
            countryCode: countryCode
        )
    }
}
