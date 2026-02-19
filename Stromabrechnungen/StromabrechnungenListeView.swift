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

    @State private var zuLoeschende: Stromabrechnung? = nil
    @State private var zeigeLoeschenBestaetigung = false

    private var sortierteAbrechnungen: [Stromabrechnung] {
        (gemeinschaft.stromabrechnungen ?? []).sorted { $0.datum > $1.datum }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortierteAbrechnungen) { abrechnung in
                    StromabrechnungListItemView(abrechnung: abrechnung)
                }
                .onDelete { offsets in
                    let abrechnung = offsets.map { sortierteAbrechnungen[$0] }
                    zuLoeschende = abrechnung.first
                    zeigeLoeschenBestaetigung = true
                }
            }
            .overlay {
                if sortierteAbrechnungen.isEmpty {
                    ContentUnavailableView(
                        "Keine Stromabrechnungen",
                        systemImage: "doc.plaintext",
                        description: Text("Es wurden noch keine Stromabrechnungen erstellt.")
                    )
                }
            }
            .navigationTitle("Stromabrechnungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
            }
            .confirmationDialog(
                "Stromabrechnung löschen?",
                isPresented: $zeigeLoeschenBestaetigung,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let abrechnung = zuLoeschende {
                        modelContext.delete(abrechnung)
                    }
                    zuLoeschende = nil
                }
                Button("Abbrechen", role: .cancel) {
                    zuLoeschende = nil
                }
            } message: {
                if let abrechnung = zuLoeschende {
                    Text("Die Abrechnung vom \(abrechnung.datum.formatted(date: .long, time: .omitted)) und alle zugehörigen Parteienabrechungen werden unwiderruflich gelöscht.")
                }
            }
        }
    }
}
