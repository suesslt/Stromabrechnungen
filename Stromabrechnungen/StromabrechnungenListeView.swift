//
//  StromabrechnungenListeView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct StromabrechnungenListeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft

    private var sortierteAbrechnungen: [Stromabrechnung] {
        (gemeinschaft.stromabrechnungen ?? []).sorted { $0.datum > $1.datum }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortierteAbrechnungen) { abrechnung in
                    Section {
                        LabeledContent("Datum") {
                            Text(abrechnung.datum, style: .date)
                        }
                        LabeledContent("Zeitraum") {
                            Text("\(abrechnung.abrechnungszeitraumVon, style: .date) – \(abrechnung.abrechnungszeitraumBis, style: .date)")
                        }
                        LabeledContent("Bezugsmenge") {
                            Text("\(abrechnung.abrechnungsbezugsmenge.formatted()) kWh")
                                .monospacedDigit()
                        }
                        LabeledContent("Abrechnungsbetrag") {
                            Text(abrechnung.abrechnungsbetrag, format: .currency(code: "CHF"))
                                .monospacedDigit()
                        }

                        if !(abrechnung.parteienabrechungen ?? []).isEmpty {
                            DisclosureGroup("Parteienabrechungen (\((abrechnung.parteienabrechungen ?? []).count))") {
                                ForEach(abrechnung.parteienabrechungen ?? []) { pa in
                                    HStack {
                                        Text(pa.bezugspartei?.name ?? "–")
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("\(pa.bezugsmenge.formatted()) kWh")
                                                .font(.caption)
                                                .monospacedDigit()
                                            Text(pa.betrag, format: .currency(code: "CHF"))
                                                .monospacedDigit()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: abrechnungLoeschen)
            }
            .navigationTitle("Stromabrechnungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
            }
        }
    }

    private func abrechnungLoeschen(at offsets: IndexSet) {
        let sortiert = sortierteAbrechnungen
        for index in offsets {
            modelContext.delete(sortiert[index])
        }
    }
}
