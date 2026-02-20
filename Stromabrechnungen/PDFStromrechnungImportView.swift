//
//  PDFStromrechnungImportView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit

struct PDFStromrechnungImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft

    // MARK: State

    @State private var zeigeDateiPicker = false
    @State private var pdfData: Data? = nil
    @State private var pdfVorschau: PDFDocument? = nil

    @State private var laedt = false
    @State private var fehlerMeldung: String? = nil

    // Felder (vorausgefüllt durch Claude, editierbar)
    @State private var rechnungssteller = ""
    @State private var rechnungsdatum = Date.now
    @State private var zeitraumVon = Date.now
    @State private var zeitraumBis = Date.now
    @State private var rechnungsbetrag = ""
    @State private var strombezugsmenge = ""

    @State private var felderSichtbar = false

    @State private var zeigeUeberlagerungAlert = false
    @State private var ueberlagerungsText = ""

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: PDF auswählen
                Section {
                    Button {
                        zeigeDateiPicker = true
                    } label: {
                        Label(
                            pdfData == nil ? "PDF auswählen" : "Anderes PDF wählen",
                            systemImage: "doc.badge.plus"
                        )
                    }

                    if let pdf = pdfVorschau {
                        PDFVorschauView(pdf: pdf)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text("PDF-Rechnung")
                } footer: {
                    Text("Wähle den Scan einer Stromrechnung als PDF aus. Claude AI liest die Felder automatisch aus.")
                }

                // MARK: Analyse-Button
                if pdfData != nil {
                    Section {
                        Button {
                            Task { await analysiereWithClaude() }
                        } label: {
                            if laedt {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                    Text("Claude analysiert…")
                                }
                            } else {
                                Label("Mit Claude AI analysieren", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                            }
                        }
                        .disabled(laedt)
                    }
                }

                // MARK: Fehlermeldung
                if let fehler = fehlerMeldung {
                    Section {
                        Label(fehler, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // MARK: Erkannte / editierbare Felder
                if felderSichtbar {
                    Section("Rechnungssteller") {
                        TextField("Name / Lieferant", text: $rechnungssteller)
                    }

                    Section("Datum & Zeitraum") {
                        DatePicker("Rechnungsdatum", selection: $rechnungsdatum, displayedComponents: .date)
                        DatePicker("Zeitraum von", selection: $zeitraumVon, displayedComponents: .date)
                        DatePicker("Zeitraum bis", selection: $zeitraumBis, displayedComponents: .date)
                    }

                    Section("Beträge") {
                        TextField("Rechnungsbetrag (CHF)", text: $rechnungsbetrag)
                            .keyboardType(.decimalPad)
                        TextField("Strombezugsmenge (kWh)", text: $strombezugsmenge)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("PDF importieren")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                if felderSichtbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") { speichernMitPruefung() }
                            .disabled(!eingabeGueltig)
                    }
                }
            }
            .fileImporter(
                isPresented: $zeigeDateiPicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                behandleDateiAuswahl(result)
            }
            .alert("Zeitraum-Überlagerung", isPresented: $zeigeUeberlagerungAlert) {
                Button("Trotzdem speichern", role: .destructive) { speichern() }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text(ueberlagerungsText)
            }
        }
    }

    // MARK: Hilfsmethoden

    private var eingabeGueltig: Bool {
        !rechnungssteller.trimmingCharacters(in: .whitespaces).isEmpty
        && Decimal(string: rechnungsbetrag.replacingOccurrences(of: ",", with: ".")) != nil
        && Decimal(string: strombezugsmenge.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func behandleDateiAuswahl(_ result: Result<[URL], Error>) {
        fehlerMeldung = nil
        felderSichtbar = false
        pdfData = nil
        pdfVorschau = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Security-Scoped Resource für iCloud Drive etc.
            let zugriff = url.startAccessingSecurityScopedResource()
            defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                pdfData = data
                pdfVorschau = PDFDocument(data: data)
            } else {
                fehlerMeldung = "PDF konnte nicht geladen werden."
            }
        case .failure(let error):
            fehlerMeldung = error.localizedDescription
        }
    }

    private func analysiereWithClaude() async {
        guard let data = pdfData else { return }
        laedt = true
        fehlerMeldung = nil
        felderSichtbar = false

        do {
            let erkannt = try await ClaudeService.shared.erkenneFelderAusPDF(pdfData: data)
            await MainActor.run {
                wendeErkanntesAn(erkannt)
                felderSichtbar = true
                laedt = false
            }
        } catch {
            await MainActor.run {
                fehlerMeldung = error.localizedDescription
                // Felder trotzdem anzeigen, damit manuell ausgefüllt werden kann
                felderSichtbar = true
                laedt = false
            }
        }
    }

    private func wendeErkanntesAn(_ erkannt: ErkannteStromrechnung) {
        rechnungssteller = erkannt.rechnungssteller
        rechnungsbetrag = erkannt.rechnungsbetrag
        strombezugsmenge = erkannt.strombezugsmenge

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        if let datum = formatter.date(from: erkannt.rechnungsdatum) {
            rechnungsdatum = datum
        }
        if let von = formatter.date(from: erkannt.abrechnungszeitraumVon) {
            zeitraumVon = von
        }
        if let bis = formatter.date(from: erkannt.abrechnungszeitraumBis) {
            zeitraumBis = bis
        }
    }

    private func speichernMitPruefung() {
        let ueberlagerungen = gemeinschaft.zeitraumUeberlagerungen(
            von: zeitraumVon,
            bis: zeitraumBis
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
        let menge = Decimal(string: strombezugsmenge.replacingOccurrences(of: ",", with: ".")) ?? 0

        let neu = Stromrechnung(
            rechnungssteller: rechnungssteller.trimmingCharacters(in: .whitespaces),
            abrechnungszeitraumVon: zeitraumVon,
            abrechnungszeitraumBis: zeitraumBis,
            rechnungsdatum: rechnungsdatum,
            rechnungsbetrag: betrag,
            strombezugsmenge: menge,
            stromgemeinschaft: gemeinschaft
        )
        modelContext.insert(neu)
        
        // Automatisch eine Delta-Stromabrechnung erstellen
        gemeinschaft.erstelleDeltaAbrechnung(modelContext: modelContext)
        
        dismiss()
    }
}

// MARK: - PDF Vorschau (PDFKit in SwiftUI)

private struct PDFVorschauView: UIViewRepresentable {
    let pdf: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.backgroundColor = .secondarySystemBackground
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdf
    }
}
