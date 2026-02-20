//
//  StromrechnungBearbeitenView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct StromrechnungBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft

    /// `nil` = Neu anlegen
    var rechnung: Stromrechnung?

    @State private var rechnungssteller = ""
    @State private var rechnungsdatum = Date.now
    @State private var zeitraumVon = Date.now
    @State private var zeitraumBis = Date.now
    @State private var rechnungsbetrag = ""
    @State private var strombezugsmenge = ""

    @State private var zeigeUeberlagerungAlert = false
    @State private var ueberlagerungsText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Rechnungssteller") {
                    TextField("Name / Lieferant", text: $rechnungssteller)
                }
                Section("Datum & Zeitraum") {
                    DatePicker("Rechnungsdatum", selection: $rechnungsdatum, displayedComponents: .date)
                    DatePicker("Zeitraum von", selection: $zeitraumVon, displayedComponents: .date)
                    DatePicker("Zeitraum bis", selection: $zeitraumBis, displayedComponents: .date)
                }
                Section("Beträge") {
                    TextField("Rechnungsbetrag (CHF)", text: $rechnungsbetrag)
                        .keyboardType(.decimalPad)
                    TextField("Strombezugsmenge (kWh)", text: $strombezugsmenge)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(rechnung == nil ? "Neue Stromrechnung" : "Rechnung bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichernMitPruefung() }
                        .disabled(!eingabeGueltig)
                }
            }
            .onAppear { vorbelegen() }
            .alert("Zeitraum-Überlagerung", isPresented: $zeigeUeberlagerungAlert) {
                Button("Trotzdem speichern", role: .destructive) { speichern() }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text(ueberlagerungsText)
            }
        }
    }

    private var eingabeGueltig: Bool {
        !rechnungssteller.trimmingCharacters(in: .whitespaces).isEmpty
        && Decimal(string: rechnungsbetrag.replacingOccurrences(of: ",", with: ".")) != nil
        && Decimal(string: strombezugsmenge.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func vorbelegen() {
        guard let r = rechnung else { return }
        rechnungssteller = r.rechnungssteller
        rechnungsdatum = r.rechnungsdatum
        zeitraumVon = r.abrechnungszeitraumVon
        zeitraumBis = r.abrechnungszeitraumBis
        rechnungsbetrag = "\(r.rechnungsbetrag)"
        strombezugsmenge = "\(r.strombezugsmenge)"
    }

    private func speichernMitPruefung() {
        let ueberlagerungen = gemeinschaft.zeitraumUeberlagerungen(
            von: zeitraumVon,
            bis: zeitraumBis,
            ausgenommenId: rechnung?.persistentModelID
        )
        if let erste = ueberlagerungen.first {
            ueberlagerungsText = erste.erklaerung(neuerVon: zeitraumVon, neuerBis: zeitraumBis)
            zeigeUeberlagerungAlert = true
        } else {
            speichern()
        }
    }

    private func speichern() {
        let betrag = Decimal(string: rechnungsbetrag.replacingOccurrences(of: ",", with: ".")) ?? 0
        let menge = Decimal(string: strombezugsmenge.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let r = rechnung {
            // Existierende Rechnung bearbeiten
            r.rechnungssteller = rechnungssteller.trimmingCharacters(in: .whitespaces)
            r.rechnungsdatum = rechnungsdatum
            r.abrechnungszeitraumVon = zeitraumVon
            r.abrechnungszeitraumBis = zeitraumBis
            r.rechnungsbetrag = betrag
            r.strombezugsmenge = menge
        } else {
            // Neue Rechnung anlegen
            let neu = Stromrechnung(
                rechnungssteller: rechnungssteller.trimmingCharacters(in: .whitespaces),
                abrechnungszeitraumVon: zeitraumVon,
                abrechnungszeitraumBis: zeitraumBis,
                rechnungsdatum: rechnungsdatum,
                rechnungsbetrag: betrag,
                strombezugsmenge: menge,
                stromgemeinschaft: gemeinschaft
            )
            modelContext.insert(neu)
        }
        
        // Delta-Abrechnung erstellen (bei Neu anlegen UND Bearbeiten)
        gemeinschaft.erstelleDeltaAbrechnung(modelContext: modelContext)
        
        dismiss()
    }
}
