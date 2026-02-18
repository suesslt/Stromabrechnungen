//
//  StromrechnungenListeView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct StromrechnungenListeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft

    @State private var zeigeNeuAnlegen = false

    private var sortierteRechnungen: [Stromrechnung] {
        gemeinschaft.stromrechnungen.sorted { $0.rechnungsdatum > $1.rechnungsdatum }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortierteRechnungen) { rechnung in
                    Section {
                        LabeledContent("Rechnungssteller", value: rechnung.rechnungssteller)
                        LabeledContent("Rechnungsdatum") {
                            Text(rechnung.rechnungsdatum, style: .date)
                        }
                        LabeledContent("Zeitraum") {
                            Text("\(rechnung.abrechnungszeitraumVon, style: .date) – \(rechnung.abrechnungszeitraumBis, style: .date)")
                        }
                        LabeledContent("Strombezug") {
                            Text("\(rechnung.strombezugsmenge.formatted()) kWh")
                                .monospacedDigit()
                        }
                        LabeledContent("Rechnungsbetrag") {
                            Text(rechnung.rechnungsbetrag, format: .currency(code: "CHF"))
                                .monospacedDigit()
                        }
                    }
                }
                .onDelete(perform: rechnungLoeschen)
            }
            .navigationTitle("Stromrechnungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        zeigeNeuAnlegen = true
                    } label: {
                        Label("Neue Stromrechnung", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $zeigeNeuAnlegen) {
                StromrechnungBearbeitenView(gemeinschaft: gemeinschaft)
            }
        }
    }

    private func rechnungLoeschen(at offsets: IndexSet) {
        let sortiert = sortierteRechnungen
        for index in offsets {
            modelContext.delete(sortiert[index])
        }
    }
}
