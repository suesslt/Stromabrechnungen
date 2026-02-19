//
//  BezugsparteiDetailView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct BezugsparteiDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft
    let partei: Bezugspartei

    @State private var zeigeBearbeiten = false
    @State private var zeigeNeueRechnung = false

    // MARK: - Berechnete Werte

    /// Summe aller Parteienabrechungs-Beträge
    private var summeAbrechnungsBetrag: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.betrag }
    }

    /// Summe aller Parteienabrechungs-Bezugsmengen
    private var summeAbrechnungsMenge: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.bezugsmenge }
    }

    /// Summe aller bereits in Rechnungen abgerechneten Beträge
    private var summeRechnungsBetrag: Decimal {
        (partei.parteienrechnungen ?? []).reduce(0) { $0 + $1.abgerechneterBetrag }
    }

    /// Summe aller bereits in Rechnungen abgerechneten Bezugsmengen
    private var summeRechnungsMenge: Decimal {
        (partei.parteienrechnungen ?? []).reduce(0) { $0 + $1.abgerechneteBezugsmenge }
    }

    /// Bereits abgerechneter Betrag = Abrechnungen minus gestellte Rechnungen
    private var abgerechnetBetrag: Decimal {
        summeAbrechnungsBetrag - summeRechnungsBetrag
    }

    /// Bereits abgerechnete Bezugsmenge = Abrechnungen minus gestellte Rechnungen
    private var abgerechnetMenge: Decimal {
        summeAbrechnungsMenge - summeRechnungsMenge
    }

    /// Nicht verrechneter Gesamtbetrag der Gemeinschaft
    private var gemeinschaftOffenBetrag: Decimal {
        let rechnungen = (gemeinschaft.stromrechnungen ?? []).reduce(Decimal(0)) { $0 + $1.rechnungsbetrag }
        let abgerechnet = (gemeinschaft.stromabrechnungen ?? []).reduce(Decimal(0)) { $0 + $1.abrechnungsbetrag }
        return rechnungen - abgerechnet
    }

    /// Nicht verrechnete Gesamtmenge der Gemeinschaft
    private var gemeinschaftOffenMenge: Decimal {
        let bezug = (gemeinschaft.stromrechnungen ?? []).reduce(Decimal(0)) { $0 + $1.strombezugsmenge }
        let abgerechnet = (gemeinschaft.stromabrechnungen ?? []).reduce(Decimal(0)) { $0 + $1.abrechnungsbezugsmenge }
        return bezug - abgerechnet
    }

    /// Offener anteiliger Betrag = prozentualer Anteil am noch nicht abgerechneten Gemeinschaftsbetrag
    private var offenerAnteiligBetrag: Decimal {
        (gemeinschaftOffenBetrag * partei.anteil / 100).rounded(scale: 2)
    }

    /// Offene anteilige Bezugsmenge
    private var offeneAnteiligeMenge: Decimal {
        (gemeinschaftOffenMenge * partei.anteil / 100).rounded(scale: 3)
    }

    // MARK: - Body

    var body: some View {
        List {
            // MARK: Adresse
            Section("Adresse") {
                let hatAdresse = !partei.street.isEmpty || !partei.city.isEmpty
                if hatAdresse {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partei.name)
                            .font(.headline)
                        if !partei.street.isEmpty || !partei.houseNumber.isEmpty {
                            Text("\(partei.street) \(partei.houseNumber)".trimmingCharacters(in: .whitespaces))
                                .foregroundStyle(.secondary)
                        }
                        if !partei.postalCode.isEmpty || !partei.city.isEmpty {
                            Text("\(partei.postalCode) \(partei.city)".trimmingCharacters(in: .whitespaces))
                                .foregroundStyle(.secondary)
                        }
                        if !partei.countryCode.isEmpty {
                            Text(partei.countryCode)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("Keine Adresse hinterlegt.")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: Anteil
            Section("Anteil an der Gemeinschaft") {
                LabeledContent("Anteil") {
                    Text("\(partei.anteil.formatted()) %")
                        .monospacedDigit()
                }
            }

            // MARK: Offene Beträge
            Section {
                LabeledContent("Offener anteiliger Betrag") {
                    Text(offenerAnteiligBetrag, format: .currency(code: "CHF"))
                        .monospacedDigit()
                        .foregroundStyle(offenerAnteiligBetrag > 0 ? .orange : .secondary)
                        .bold()
                }
                LabeledContent("Offene anteilige Bezugsmenge") {
                    Text("\(offeneAnteiligeMenge.formatted()) kWh")
                        .monospacedDigit()
                        .foregroundStyle(offeneAnteiligeMenge > 0 ? .orange : .secondary)
                        .bold()
                }
            } header: {
                Text("Offen (noch nicht abgerechnet)")
            } footer: {
                Text("Prozentualer Anteil (\(partei.anteil.formatted()) %) am noch nicht abgerechneten Betrag und der Bezugsmenge der Gemeinschaft.")
            }

            // MARK: Bereits abgerechnet
            Section {
                LabeledContent("Abgerechneter Betrag") {
                    Text(abgerechnetBetrag, format: .currency(code: "CHF"))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Abgerechnete Bezugsmenge") {
                    Text("\(abgerechnetMenge.formatted()) kWh")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Bisher abgerechnet")
            } footer: {
                Text("Summe der Parteienabrechnungen abzüglich bereits gestellter Parteienrechnungen.")
            }

            // MARK: Parteienrechnungen
            Section {
                let rechnungen = (partei.parteienrechnungen ?? [])
                    .sorted { $0.rechnungsdatum > $1.rechnungsdatum }

                if rechnungen.isEmpty {
                    Text("Noch keine Rechnungen vorhanden.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rechnungen) { rechnung in
                        ParteienrechnungListItemView(rechnung: rechnung)
                    }
                    .onDelete { indexSet in
                        rechnungenLoeschen(rechnungen: rechnungen, at: indexSet)
                    }
                }

                Button {
                    zeigeNeueRechnung = true
                } label: {
                    Label("Neue Rechnung erstellen", systemImage: "plus.circle")
                }
            } header: {
                Text("Parteienrechnungen")
            }
        }
        .navigationTitle(partei.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { zeigeBearbeiten = true }
            }
        }
        .sheet(isPresented: $zeigeBearbeiten) {
            BezugsparteiBearbeitenView(gemeinschaft: gemeinschaft, partei: partei)
        }
        .sheet(isPresented: $zeigeNeueRechnung) {
            ParteienrechnungErstellenView(partei: partei, gemeinschaft: gemeinschaft)
        }
    }

    // MARK: - Aktionen

    private func rechnungenLoeschen(rechnungen: [Parteienrechnung], at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(rechnungen[index])
        }
    }
}

// MARK: - Listenzeile für eine Parteienrechnung

private struct ParteienrechnungListItemView: View {
    let rechnung: Parteienrechnung

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rechnung.rechnungsdatum, style: .date)
                    .font(.headline)
                Spacer()
                Text(rechnung.abgerechneterBetrag, format: .currency(code: "CHF"))
                    .monospacedDigit()
                    .bold()
            }
            HStack {
                Text(
                    "\(rechnung.rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(rechnung.rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text("\(rechnung.abgerechneteBezugsmenge.formatted()) kWh")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(rechnung.rechnungsstatus.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusFarbe(rechnung.rechnungsstatus).opacity(0.15))
                .foregroundStyle(statusFarbe(rechnung.rechnungsstatus))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }

    private func statusFarbe(_ status: Rechnungsstatus) -> Color {
        switch status {
        case .offen:     return .orange
        case .bezahlt:   return .green
        case .storniert: return .red
        }
    }
}

// MARK: - Decimal Hilfserweiterung

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, scale, .plain)
        return result
    }
}
