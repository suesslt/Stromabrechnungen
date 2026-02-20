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
    @State private var zuBearbeitendeRechnung: Stromrechnung? = nil

    private var sortierteRechnungen: [Stromrechnung] {
        (gemeinschaft.stromrechnungen ?? []).sorted { $0.abrechnungszeitraumVon < $1.abrechnungszeitraumVon }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortierteRechnungen) { rechnung in
                    StromrechnungListItemView(rechnung: rechnung)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                rechnungLoeschen(rechnung)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            
                            Button {
                                zuBearbeitendeRechnung = rechnung
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                zuBearbeitendeRechnung = rechnung
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                rechnungLoeschen(rechnung)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
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
            .sheet(item: $zuBearbeitendeRechnung) { rechnung in
                StromrechnungBearbeitenView(gemeinschaft: gemeinschaft, rechnung: rechnung)
            }
        }
    }

    // MARK: Aktionen

    private func rechnungLoeschen(_ rechnung: Stromrechnung) {
        modelContext.delete(rechnung)
        
        // Delta-Abrechnung nach dem Löschen erstellen
        gemeinschaft.erstelleDeltaAbrechnung(modelContext: modelContext)
    }
}
