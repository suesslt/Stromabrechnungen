import Foundation
import SwiftData
import SwiftUI

@Model
final class Stromgemeinschaft {
    var bezeichnung: String = ""
    var abrechnungskonto: String = ""
    var bild: Data?

    @Relationship(deleteRule: .cascade, inverse: \Stromrechnung.stromgemeinschaft)
    var stromrechnungen: [Stromrechnung]?

    @Relationship(deleteRule: .cascade, inverse: \Stromabrechnung.stromgemeinschaft)
    var stromabrechnungen: [Stromabrechnung]?

    @Relationship(deleteRule: .cascade, inverse: \Bezugspartei.stromgemeinschaft)
    var bezugsparteien: [Bezugspartei]?

    init(bezeichnung: String, abrechnungskonto: String, bild: Data? = nil) {
        self.bezeichnung = bezeichnung
        self.abrechnungskonto = abrechnungskonto
        self.bild = bild
    }
}
