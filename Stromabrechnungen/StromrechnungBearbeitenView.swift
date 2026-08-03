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
    @State private var gutschrift = ""
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
                    LabeledContent("Rechnungsbetrag") {
                        TextField("CHF", text: $rechnungsbetrag)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    LabeledContent("Gutschrift") {
                        TextField("CHF", text: $gutschrift)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    if let verrechenbar = verrechenbarerBetrag {
                        LabeledContent("Verrechenbar") {
                            Text(verrechenbar, format: .currency(code: "CHF"))
                                .monospacedDigit()
                                .foregroundStyle(verrechenbar < 0 ? .red : .secondary)
                        }
                    }
                    LabeledContent("Lieferung") {
                        TextField("kWh", text: $strombezugsmenge)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
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
        && (gutschrift.trimmingCharacters(in: .whitespaces).isEmpty
            || Decimal(string: gutschrift.replacingOccurrences(of: ",", with: ".")) != nil)
    }

    /// Live berechneter verrechenbarer Betrag, sobald beide Felder valide sind.
    private var verrechenbarerBetrag: Decimal? {
        guard let betrag = Decimal(string: rechnungsbetrag.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        let g = Decimal(string: gutschrift.replacingOccurrences(of: ",", with: ".")) ?? 0
        return betrag - g
    }

    private func vorbelegen() {
        guard let r = rechnung else { return }
        rechnungssteller = r.rechnungssteller
        rechnungsdatum = r.rechnungsdatum
        zeitraumVon = r.abrechnungszeitraumVon
        zeitraumBis = r.abrechnungszeitraumBis
        rechnungsbetrag = "\(r.rechnungsbetrag)"
        gutschrift = r.gutschrift == 0 ? "" : "\(r.gutschrift)"
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
        let gut = Decimal(string: gutschrift.replacingOccurrences(of: ",", with: ".")) ?? 0
        let menge = Decimal(string: strombezugsmenge.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let r = rechnung {
            // Existierende Rechnung bearbeiten
            r.rechnungssteller = rechnungssteller.trimmingCharacters(in: .whitespaces)
            r.rechnungsdatum = rechnungsdatum
            r.abrechnungszeitraumVon = zeitraumVon
            r.abrechnungszeitraumBis = zeitraumBis
            r.rechnungsbetrag = betrag
            r.gutschrift = gut
            r.strombezugsmenge = menge
        } else {
            // Neue Rechnung anlegen
            let neu = Stromrechnung(
                rechnungssteller: rechnungssteller.trimmingCharacters(in: .whitespaces),
                abrechnungszeitraumVon: zeitraumVon,
                abrechnungszeitraumBis: zeitraumBis,
                rechnungsdatum: rechnungsdatum,
                rechnungsbetrag: betrag,
                gutschrift: gut,
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
