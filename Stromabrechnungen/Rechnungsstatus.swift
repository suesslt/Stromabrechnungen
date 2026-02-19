import Foundation

enum Rechnungsstatus: String, Codable, CaseIterable {
    case offen = "Offen"
    case bezahlt = "Bezahlt"
    case storniert = "Storniert"
}
