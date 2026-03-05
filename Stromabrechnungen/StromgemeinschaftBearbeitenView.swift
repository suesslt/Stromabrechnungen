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

    // MARK: - Stammdaten
    @State private var bezeichnung = ""
    @State private var abrechnungskonto = ""
    @State private var bildAuswahl: PhotosPickerItem?
    @State private var bildData: Data?

    // MARK: - Kreditor-Adresse
    @State private var kreditorName = ""
    @State private var kreditorAdresszusatz = ""
    @State private var kreditorStrasse = ""
    @State private var kreditorHausnummer = ""
    @State private var kreditorPLZ = ""
    @State private var kreditorOrt = ""
    @State private var kreditorLand = "CH"

    // MARK: - Rechnungstexte
    @State private var rechnungLeadingText = ""
    @State private var rechnungTrailingText = ""

    // MARK: - Validierung

    private var ibanValidierung: String? {
        IBANValidator.validationMessage(abrechnungskonto)
    }

    private var istGueltig: Bool {
        !bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty
            && (abrechnungskonto.trimmingCharacters(in: .whitespaces).isEmpty
                || IBANValidator.isValid(abrechnungskonto))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stammdaten") {
                    TextField("Bezeichnung", text: $bezeichnung)
                }

                Section {
                    TextField("IBAN (z. B. CH93 0076 2011 6238 5295 7)", text: $abrechnungskonto)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                    if let fehler = ibanValidierung {
                        Label(fehler, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else if !abrechnungskonto.trimmingCharacters(in: .whitespaces).isEmpty {
                        Label("IBAN gültig", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                } header: {
                    Text("Abrechnungskonto")
                }

                Section("Kreditor-Adresse") {
                    TextField("Firma / Name", text: $kreditorName)
                        .textContentType(.organizationName)
                    TextField("Adresszusatz", text: $kreditorAdresszusatz)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("Strasse", text: $kreditorStrasse)
                            .textContentType(.streetAddressLine1)
                            .frame(maxWidth: .infinity)
                        TextField("Nr.", text: $kreditorHausnummer)
                            .textContentType(.streetAddressLine2)
                            .frame(width: 64)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("PLZ", text: $kreditorPLZ)
                            .textContentType(.postalCode)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                        TextField("Ort", text: $kreditorOrt)
                            .textContentType(.addressCity)
                            .frame(maxWidth: .infinity)
                    }
                    TextField("Ländercode (z. B. CH)", text: $kreditorLand)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: kreditorLand) { _, newValue in
                            kreditorLand = String(newValue.uppercased().prefix(2))
                        }
                }

                Section {
                    TextField("Einleitungstext", text: $rechnungLeadingText, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Schlusstext", text: $rechnungTrailingText, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Rechnungstexte")
                } footer: {
                    Text("Platzhalter: {name}, {zeitraumVon}, {zeitraumBis}, {betrag}, {menge}, {rechnungsdatum}, {iban}")
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
                        .disabled(!istGueltig)
                }
            }
            .task(id: bildAuswahl) {
                if let item = bildAuswahl {
                    bildData = try? await item.loadTransferable(type: Data.self)
                }
            }
            .onAppear { vorbelegen() }
        }
    }

    // MARK: - Hilfsmethoden

    private func vorbelegen() {
        guard let g = gemeinschaft else { return }
        bezeichnung = g.bezeichnung
        abrechnungskonto = g.abrechnungskonto
        bildData = g.bild
        kreditorName = g.kreditorName
        kreditorAdresszusatz = g.kreditorAdresszusatz
        kreditorStrasse = g.kreditorStrasse
        kreditorHausnummer = g.kreditorHausnummer
        kreditorPLZ = g.kreditorPLZ
        kreditorOrt = g.kreditorOrt
        kreditorLand = g.kreditorLand
        rechnungLeadingText = g.rechnungLeadingText
        rechnungTrailingText = g.rechnungTrailingText
    }

    private func speichern() {
        if let g = gemeinschaft {
            g.bezeichnung = bezeichnung.trimmingCharacters(in: .whitespaces)
            g.abrechnungskonto = abrechnungskonto.trimmingCharacters(in: .whitespaces)
            g.bild = bildData
            g.kreditorName = kreditorName.trimmingCharacters(in: .whitespaces)
            g.kreditorAdresszusatz = kreditorAdresszusatz.trimmingCharacters(in: .whitespaces)
            g.kreditorStrasse = kreditorStrasse.trimmingCharacters(in: .whitespaces)
            g.kreditorHausnummer = kreditorHausnummer.trimmingCharacters(in: .whitespaces)
            g.kreditorPLZ = kreditorPLZ.trimmingCharacters(in: .whitespaces)
            g.kreditorOrt = kreditorOrt.trimmingCharacters(in: .whitespaces)
            g.kreditorLand = kreditorLand.trimmingCharacters(in: .whitespaces)
            g.rechnungLeadingText = rechnungLeadingText
            g.rechnungTrailingText = rechnungTrailingText
        } else {
            let neu = Stromgemeinschaft(
                bezeichnung: bezeichnung.trimmingCharacters(in: .whitespaces),
                abrechnungskonto: abrechnungskonto.trimmingCharacters(in: .whitespaces),
                bild: bildData,
                kreditorName: kreditorName.trimmingCharacters(in: .whitespaces),
                kreditorAdresszusatz: kreditorAdresszusatz.trimmingCharacters(in: .whitespaces),
                kreditorStrasse: kreditorStrasse.trimmingCharacters(in: .whitespaces),
                kreditorHausnummer: kreditorHausnummer.trimmingCharacters(in: .whitespaces),
                kreditorPLZ: kreditorPLZ.trimmingCharacters(in: .whitespaces),
                kreditorOrt: kreditorOrt.trimmingCharacters(in: .whitespaces),
                kreditorLand: kreditorLand.trimmingCharacters(in: .whitespaces),
                rechnungLeadingText: rechnungLeadingText,
                rechnungTrailingText: rechnungTrailingText
            )
            modelContext.insert(neu)
        }
        dismiss()
    }
}
