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
    @State private var zeigePDFImport = false

    private var sortierteRechnungen: [Stromrechnung] {
        (gemeinschaft.stromrechnungen ?? []).sorted { $0.abrechnungszeitraumVon < $1.abrechnungszeitraumVon }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortierteRechnungen) { rechnung in
                    StromrechnungListItemView(rechnung: rechnung)
                }
                .onDelete(perform: rechnungLoeschen)
            }
            .overlay {
                if sortierteRechnungen.isEmpty {
                    ContentUnavailableView(
                        "Keine Stromrechnungen",
                        systemImage: "doc.text",
                        description: Text("Es wurden noch keine Stromrechnungen erfasst.")
                    )
                }
            }
            .navigationTitle("Stromrechnungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            zeigeNeuAnlegen = true
                        } label: {
                            Label("Manuell erfassen", systemImage: "square.and.pencil")
                        }
                        Button {
                            zeigePDFImport = true
                        } label: {
                            Label("PDF mit Claude AI importieren", systemImage: "sparkles")
                        }
                    } label: {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $zeigeNeuAnlegen) {
                StromrechnungBearbeitenView(gemeinschaft: gemeinschaft)
            }
            .sheet(isPresented: $zeigePDFImport) {
                PDFStromrechnungImportView(gemeinschaft: gemeinschaft)
            }
        }
    }

    // MARK: Aktionen

    private func rechnungLoeschen(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortierteRechnungen[index])
        }
    }
}
