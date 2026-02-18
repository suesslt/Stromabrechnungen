//
//  ZeitraumPruefung.swift
//  Stromabrechnungen
//

import Foundation
import SwiftData

/// Beschreibt eine Zeitraum-Überlagerung mit einer bereits vorhandenen Stromrechnung.
struct ZeitraumUeberlagerung {
    let vorhandeneRechnung: Stromrechnung

    /// Überlappender Zeitraum (Schnittmenge)
    let ueberlappungVon: Date
    let ueberlappungBis: Date

    /// Lesbare Beschreibung für den Alert
    func erklaerung(neuerVon: Date, neuerBis: Date) -> String {
        let fmt: (Date) -> String = {
            $0.formatted(date: .long, time: .omitted)
        }
        return """
        Die neue Rechnung (\(fmt(neuerVon)) – \(fmt(neuerBis))) überschneidet sich mit:

        „\(vorhandeneRechnung.rechnungssteller)"
        \(fmt(vorhandeneRechnung.abrechnungszeitraumVon)) – \(fmt(vorhandeneRechnung.abrechnungszeitraumBis))

        Überlappung: \(fmt(ueberlappungVon)) – \(fmt(ueberlappungBis))

        Bitte prüfe, ob es sich um eine Doppelerfassung handelt oder korrigiere den Zeitraum.
        """
    }
}

extension Stromgemeinschaft {

    /// Gibt alle Zeitraum-Überlagerungen der bestehenden Stromrechnungen mit dem
    /// angegebenen Zeitraum zurück. Beim Bearbeiten einer vorhandenen Rechnung kann
    /// deren eigene ID via `ausgenommenId` ausgeschlossen werden.
    func zeitraumUeberlagerungen(
        von: Date,
        bis: Date,
        ausgenommenId: PersistentIdentifier? = nil
    ) -> [ZeitraumUeberlagerung] {
        guard von < bis else { return [] }

        return (stromrechnungen ?? [])
            .filter { $0.persistentModelID != ausgenommenId }
            .compactMap { vorhandene in
                // Zwei Intervalle [a,b] und [c,d] überlappen wenn a < d && c < b
                let ueberlappVon = max(von, vorhandene.abrechnungszeitraumVon)
                let ueberlappBis = min(bis, vorhandene.abrechnungszeitraumBis)
                guard ueberlappVon < ueberlappBis else { return nil }
                return ZeitraumUeberlagerung(
                    vorhandeneRechnung: vorhandene,
                    ueberlappungVon: ueberlappVon,
                    ueberlappungBis: ueberlappBis
                )
            }
    }
}
