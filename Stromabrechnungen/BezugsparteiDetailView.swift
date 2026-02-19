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

    // MARK: - Berechnete Werte

    /// Bereits abgerechneter Betrag dieser Partei (Summe aller Parteienabrechungen)
    private var abgerechnetBetrag: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.betrag }
    }

    /// Bereits abgerechnete Bezugsmenge dieser Partei
    private var abgerechnetMenge: Decimal {
        (partei.parteienabrechungen ?? []).reduce(0) { $0 + $1.bezugsmenge }
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
