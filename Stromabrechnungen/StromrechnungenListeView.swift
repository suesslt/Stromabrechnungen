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
    @State private var zuLoeschende: Stromrechnung? = nil
    @State private var zeigeLoeschenBestaetigung = false

    private var sortierteRechnungen: [Stromrechnung] {
        (gemeinschaft.stromrechnungen ?? []).sorted { $0.rechnungsdatum > $1.rechnungsdatum }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sortierteRechnungen.isEmpty {
                    ContentUnavailableView(
                        "Keine Stromrechnungen",
                        systemImage: "doc.text",
                        description: Text("Es wurden noch keine Stromrechnungen erfasst.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sortierteRechnungen) { rechnung in
                            RechnungsKarte(rechnung: rechnung) {
                                zuLoeschende = rechnung
                                zeigeLoeschenBestaetigung = true
                            }
                        }
                    }
                    .padding()
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
            .confirmationDialog(
                "Stromrechnung löschen?",
                isPresented: $zeigeLoeschenBestaetigung,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let rechnung = zuLoeschende {
                        modelContext.delete(rechnung)
                    }
                    zuLoeschende = nil
                }
                Button("Abbrechen", role: .cancel) {
                    zuLoeschende = nil
                }
            } message: {
                if let rechnung = zuLoeschende {
                    Text("Die Stromrechnung von \(rechnung.rechnungssteller) vom \(rechnung.rechnungsdatum.formatted(date: .long, time: .omitted)) wird unwiderruflich gelöscht.")
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
}

// MARK: - Rechnungskarte

private struct RechnungsKarte: View {
    let rechnung: Stromrechnung
    let onDelete: () -> Void

    private static let chfFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CHF"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let mengenFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Kopfzeile
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rechnung.rechnungssteller)
                        .font(.headline)
                    Text(
                        "\(rechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(rechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(rechnung.rechnungsdatum, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // MARK: Kennzahlen
            HStack(spacing: 0) {
                KennzahlZelle(
                    titel: "Strombezug",
                    wert: "\(Self.mengenFormatter.string(from: rechnung.strombezugsmenge as NSDecimalNumber) ?? "") kWh"
                )

                Divider().frame(height: 40)

                KennzahlZelle(
                    titel: "Betrag",
                    wert: Self.chfFormatter.string(from: rechnung.rechnungsbetrag as NSDecimalNumber) ?? ""
                )
            }
            .padding(.vertical, 10)

        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Hilfszelle

private struct KennzahlZelle: View {
    let titel: String
    let wert: String

    var body: some View {
        VStack(spacing: 2) {
            Text(titel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(wert)
                .font(.subheadline.monospacedDigit())
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}
