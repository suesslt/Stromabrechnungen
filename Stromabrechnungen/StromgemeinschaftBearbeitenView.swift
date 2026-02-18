//
//  StromgemeinschaftBearbeitenView.swift
//  Stromabrechnungen
//

import SwiftUI
import PhotosUI
import SwiftData

struct StromgemeinschaftBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// `nil` = Neu anlegen, sonst bearbeiten
    var gemeinschaft: Stromgemeinschaft?

    @State private var bezeichnung = ""
    @State private var abrechnungskonto = ""
    @State private var bildAuswahl: PhotosPickerItem?
    @State private var bildData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Stammdaten") {
                    TextField("Bezeichnung", text: $bezeichnung)
                    TextField("Abrechnungskonto", text: $abrechnungskonto)
                }

                Section("Bild") {
                    PhotosPicker(selection: $bildAuswahl, matching: .images) {
                        Label(
                            bildData == nil ? "Bild auswählen" : "Bild ändern",
                            systemImage: "photo"
                        )
                    }
                    if let daten = bildData, let uiImg = UIImage(data: daten) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if bildData != nil {
                        Button("Bild entfernen", role: .destructive) {
                            bildData = nil
                            bildAuswahl = nil
                        }
                    }
                }
            }
            .navigationTitle(gemeinschaft == nil ? "Neue Stromgemeinschaft" : "Bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .task(id: bildAuswahl) {
                if let item = bildAuswahl {
                    bildData = try? await item.loadTransferable(type: Data.self)
                }
            }
            .onAppear {
                if let g = gemeinschaft {
                    bezeichnung = g.bezeichnung
                    abrechnungskonto = g.abrechnungskonto
                    bildData = g.bild
                }
            }
        }
    }

    private func speichern() {
        if let g = gemeinschaft {
            g.bezeichnung = bezeichnung.trimmingCharacters(in: .whitespaces)
            g.abrechnungskonto = abrechnungskonto.trimmingCharacters(in: .whitespaces)
            g.bild = bildData
        } else {
            let neu = Stromgemeinschaft(
                bezeichnung: bezeichnung.trimmingCharacters(in: .whitespaces),
                abrechnungskonto: abrechnungskonto.trimmingCharacters(in: .whitespaces),
                bild: bildData
            )
            modelContext.insert(neu)
        }
        dismiss()
    }
}
