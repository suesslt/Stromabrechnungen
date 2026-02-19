//
//  ParteienrechnungErstellenView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct ParteienrechnungErstellenView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let partei: Bezugspartei

    @State private var rechnungsdatum: Date = .now
    @State private var rechnungszeitraumVon: Date = .now
    @State private var rechnungszeitraumBis: Date = .now
    @State private var abgerechneteBezugsmenge: Decimal = 0
    @State private var abgerechneterBetrag: Decimal = 0
    @State private var rechnungsstatus: Rechnungsstatus = .offen

    // Eingabe als String, damit der Nutzer Dezimalzahlen bequem eintippen kann
    @State private var abgerechneteBezugsmengeText: String = "0"
    @State private var abgerechneterBetragText: String = "0"

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitraum") {
                    DatePicker("Rechnungsdatum", selection: $rechnungsdatum, displayedComponents: .date)
                    DatePicker("Zeitraum von", selection: $rechnungszeitraumVon, displayedComponents: .date)
                    DatePicker("Zeitraum bis", selection: $rechnungszeitraumBis, displayedComponents: .date)
                }

                Section("Beträge") {
                    LabeledContent("Abgerechneter Betrag (CHF)") {
                        TextField("0.00", text: $abgerechneterBetragText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    LabeledContent("Abgerechnete Bezugsmenge (kWh)") {
                        TextField("0.000", text: $abgerechneteBezugsmengeText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Status") {
                    Picker("Rechnungsstatus", selection: $rechnungsstatus) {
                        ForEach(Rechnungsstatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Neue Rechnung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(!eingabeGueltig)
                }
            }
        }
    }

    private var eingabeGueltig: Bool {
        Decimal(string: abgerechneterBetragText) != nil &&
        Decimal(string: abgerechneteBezugsmengeText) != nil &&
        rechnungszeitraumBis >= rechnungszeitraumVon
    }

    private func speichern() {
        guard
            let betrag = Decimal(string: abgerechneterBetragText),
            let menge = Decimal(string: abgerechneteBezugsmengeText)
        else { return }

        let rechnung = Parteienrechnung(
            rechnungsdatum: rechnungsdatum,
            rechnungszeitraumVon: rechnungszeitraumVon,
            rechnungszeitraumBis: rechnungszeitraumBis,
            abgerechneteBezugsmenge: menge,
            abgerechneterBetrag: betrag,
            rechnungsstatus: rechnungsstatus,
            bezugspartei: partei
        )
        modelContext.insert(rechnung)
        dismiss()
    }
}
