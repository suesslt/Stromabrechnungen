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
    
    /// Erstellt eine neue Stromabrechnung basierend auf dem Delta zwischen 
    /// Summe aller Stromrechnungen und Summe aller Stromabrechnungen.
    /// Funktioniert auch bei negativen Delta-Beträgen (z.B. bei Korrekturen).
    func erstelleDeltaAbrechnung(modelContext: ModelContext) {
        // Summe aller Stromrechnungen
        let rechnungen = stromrechnungen ?? []
        let summeBetragRechnungen = rechnungen.reduce(Decimal(0)) { $0 + $1.rechnungsbetrag }
        let summeMengeRechnungen = rechnungen.reduce(Decimal(0)) { $0 + $1.strombezugsmenge }
        
        // Summe aller bisherigen Stromabrechnungen
        let abrechnungen = stromabrechnungen ?? []
        let summeBetragAbrechnungen = abrechnungen.reduce(Decimal(0)) { $0 + $1.abrechnungsbetrag }
        let summeMengeAbrechnungen = abrechnungen.reduce(Decimal(0)) { $0 + $1.abrechnungsbezugsmenge }
        
        // Delta berechnen (kann positiv oder negativ sein)
        let deltaBetrag = summeBetragRechnungen - summeBetragAbrechnungen
        let deltaMenge = summeMengeRechnungen - summeMengeAbrechnungen
        
        // Nur erstellen, wenn es ein Delta gibt (≠ 0)
        guard deltaBetrag != 0 || deltaMenge != 0 else { return }
        
        // Zeitraum: von der frühesten bis zur spätesten Stromrechnung
        let zeitraumVon = rechnungen.map(\.abrechnungszeitraumVon).min() ?? Date.now
        let zeitraumBis = rechnungen.map(\.abrechnungszeitraumBis).max() ?? Date.now
        
        // Neue Stromabrechnung mit Delta erstellen (auch bei negativen Beträgen)
        let deltaAbrechnung = Stromabrechnung(
            datum: Date.now,
            abrechnungszeitraumVon: zeitraumVon,
            abrechnungszeitraumBis: zeitraumBis,
            abrechnungsbetrag: deltaBetrag,
            abrechnungsbezugsmenge: deltaMenge,
            stromgemeinschaft: self
        )
        modelContext.insert(deltaAbrechnung)
        
        // Parteienabrechungen proportional zu den Anteilen aufteilen
        // (auch bei negativen Beträgen - die Verteilungslogik bleibt gleich)
        erstelleParteienabrechungen(
            fuerAbrechnung: deltaAbrechnung,
            gesamtBetrag: deltaBetrag,
            gesamtMenge: deltaMenge,
            modelContext: modelContext
        )
    }
    
    /// Erstellt Parteienabrechungen für eine Stromabrechnung, proportional zu den Anteilen der Bezugsparteien.
    /// Funktioniert korrekt bei positiven und negativen Beträgen.
    private func erstelleParteienabrechungen(
        fuerAbrechnung abrechnung: Stromabrechnung,
        gesamtBetrag: Decimal,
        gesamtMenge: Decimal,
        modelContext: ModelContext
    ) {
        let parteien = (bezugsparteien ?? []).sorted { $0.name < $1.name }
        
        guard !parteien.isEmpty else { return }
        
        // Der letzte Eintrag erhält den verbleibenden Rest, damit Betrag und Menge
        // in der Summe exakt übereinstimmen und keine Rundungsdifferenzen entstehen.
        var restBetrag = gesamtBetrag
        var restMenge = gesamtMenge
        
        for (idx, partei) in parteien.enumerated() {
            let istLetzte = idx == parteien.count - 1
            
            let parteiBetrag: Decimal
            let parteiBezugsmenge: Decimal
            
            if istLetzte {
                parteiBetrag = restBetrag
                parteiBezugsmenge = restMenge
            } else {
                parteiBetrag = (gesamtBetrag * partei.anteil / 100).rounded(scale: 2)
                parteiBezugsmenge = (gesamtMenge * partei.anteil / 100).rounded(scale: 3)
                restBetrag -= parteiBetrag
                restMenge -= parteiBezugsmenge
            }
            
            let pa = Parteienabrechnung(
                betrag: parteiBetrag,
                bezugsmenge: parteiBezugsmenge,
                stromabrechnung: abrechnung,
                bezugspartei: partei
            )
            modelContext.insert(pa)
        }
    }
}
// MARK: - Decimal Hilfserweiterung

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, scale, .plain)
        return result
    }
}

