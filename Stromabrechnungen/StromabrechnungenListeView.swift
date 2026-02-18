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
            ScrollView {
                if sortierteAbrechnungen.isEmpty {
                    ContentUnavailableView(
                        "Keine Stromabrechnungen",
                        systemImage: "doc.plaintext",
                        description: Text("Es wurden noch keine Stromabrechnungen erstellt.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sortierteAbrechnungen) { abrechnung in
                            AbrechnungsKarte(abrechnung: abrechnung) {
                                zuLoeschende = abrechnung
                                zeigeLoeschenBestaetigung = true
                            }
                        }
                    }
                    .padding()
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

// MARK: - Abrechnungskarte

private struct AbrechnungsKarte: View {
    let abrechnung: Stromabrechnung
    let onDelete: () -> Void

    @State private var aufgeklappt = false

    // MARK: Formatter (einmalig erstellt, nicht bei jedem Render neu)
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
                    Text(abrechnung.datum, style: .date)
                        .font(.headline)
                    Text(
                        "\(abrechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(abrechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                    )
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
                    titel: "Bezugsmenge",
                    wert: "\(Self.mengenFormatter.string(from: abrechnung.abrechnungsbezugsmenge as NSDecimalNumber) ?? "") kWh"
                )

                Divider().frame(height: 40)

                KennzahlZelle(
                    titel: "Betrag",
                    wert: Self.chfFormatter.string(from: abrechnung.abrechnungsbetrag as NSDecimalNumber) ?? ""
                )
            }
            .padding(.vertical, 10)

            // MARK: Parteienabrechungen (aufklappbar)
            let parteien = (abrechnung.parteienabrechungen ?? [])
                .sorted { ($0.bezugspartei?.name ?? "") < ($1.bezugspartei?.name ?? "") }

            if !parteien.isEmpty {
                Divider()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        aufgeklappt.toggle()
                    }
                } label: {
                    HStack {
                        Text("Parteienabrechungen (\(parteien.count))")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(aufgeklappt ? 90 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if aufgeklappt {
                    Divider()
                    VStack(spacing: 0) {
                        ForEach(Array(parteien.enumerated()), id: \.element.id) { idx, pa in
                            HStack {
                                Text(pa.bezugspartei?.name ?? "–")
                                    .font(.subheadline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Self.mengenFormatter.string(from: pa.bezugsmenge as NSDecimalNumber) ?? "") kWh")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                    Text(Self.chfFormatter.string(from: pa.betrag as NSDecimalNumber) ?? "")
                                        .font(.subheadline)
                                        .monospacedDigit()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            if idx < parteien.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
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
