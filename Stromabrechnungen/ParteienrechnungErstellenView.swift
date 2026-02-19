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
    let gemeinschaft: Stromgemeinschaft

    @State private var rechnungsdatum: Date = .now
    @State private var rechnungszeitraumVon: Date = .now
    @State private var rechnungszeitraumBis: Date = .now
    @State private var abgerechneteBezugsmengeText: String = ""
    @State private var abgerechneterBetragText: String = ""
    @State private var rechnungsstatus: Rechnungsstatus = .offen

    // MARK: - Vorgeschlagene Werte (entspricht der Logik in BezugsparteiDetailView)

    /// Summe der Parteienabrechugen-Beträge
    private var summeAbrechnungsBetrag: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.betrag }
    }

    /// Summe der Parteienabrechugen-Bezugsmengen
    private var summeAbrechnungsMenge: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.bezugsmenge }
    }

    /// Summe der bereits in Rechnungen abgerechneten Beträge
    private var summeRechnungsBetrag: Decimal {
        (partei.parteienrechnungen ?? []).reduce(0) { $0 + $1.abgerechneterBetrag }
    }

    /// Summe der bereits in Rechnungen abgerechneten Bezugsmengen
    private var summeRechnungsMenge: Decimal {
        (partei.parteienrechnungen ?? []).reduce(0) { $0 + $1.abgerechneteBezugsmenge }
    }

    /// Noch nicht in Rechnung gestellter Betrag = Abrechnungen minus gestellte Rechnungen
    private var vorgeschlagenerBetrag: Decimal {
        summeAbrechnungsBetrag - summeRechnungsBetrag
    }

    /// Noch nicht in Rechnung gestellte Bezugsmenge = Abrechnungen minus gestellte Rechnungen
    private var vorgeschlageneMenge: Decimal {
        summeAbrechnungsMenge - summeRechnungsMenge
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitraum") {
                    DatePicker("Rechnungsdatum", selection: $rechnungsdatum, displayedComponents: .date)
                    DatePicker("Zeitraum von", selection: $rechnungszeitraumVon, displayedComponents: .date)
                    DatePicker("Zeitraum bis", selection: $rechnungszeitraumBis, displayedComponents: .date)
                }

                Section {
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
                } header: {
                    Text("Beträge")
                } footer: {
                    Text("Vorgeschlagen: \(vorgeschlagenerBetrag.formatted(.currency(code: "CHF"))) / \(vorgeschlageneMenge.formatted()) kWh (noch nicht in Rechnung gestellter Betrag)")
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
            .onAppear {
                // Vorgeschlagene Werte vorausfüllen
                abgerechneterBetragText = "\(vorgeschlagenerBetrag)"
                abgerechneteBezugsmengeText = "\(vorgeschlageneMenge)"
            }
        }
    }

    // MARK: - Hilfsmethoden

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
