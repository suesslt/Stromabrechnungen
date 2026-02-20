//
//  StromgemeinschaftDetailView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct StromgemeinschaftDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let gemeinschaft: Stromgemeinschaft

    @State private var zeigeStromrechnungen = false
    @State private var zeigeStromabrechnungen = false
    @State private var zeigeBearbeiten = false

    // MARK: Berechnete Summen

    /// [1] Summe Rechnungsbeträge aller Stromrechnungen
    private var gesamtRechnungsbetrag: Decimal {
        (gemeinschaft.stromrechnungen ?? []).reduce(0) { $0 + $1.rechnungsbetrag }
    }

    /// [2] Summe Strombezugsmengen aller Stromrechnungen
    private var gesamtStrombezugsmenge: Decimal {
        (gemeinschaft.stromrechnungen ?? []).reduce(0) { $0 + $1.strombezugsmenge }
    }

    /// Frühestes „Von"-Datum über alle Stromrechnungen (nil wenn keine vorhanden)
    private var bezugszeitraumVon: Date? {
        (gemeinschaft.stromrechnungen ?? []).map(\.abrechnungszeitraumVon).min()
    }

    /// Spätestes „Bis"-Datum über alle Stromrechnungen (nil wenn keine vorhanden)
    private var bezugszeitraumBis: Date? {
        (gemeinschaft.stromrechnungen ?? []).map(\.abrechnungszeitraumBis).max()
    }

    // MARK: Body

    var body: some View {
        List {
            // MARK: Kopfbild (falls vorhanden)
            if let bildData = gemeinschaft.bild,
               let uiImage = UIImage(data: bildData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .listRowInsets(EdgeInsets())
                }
            }

            // MARK: Abschnitt: Bisherige Bezüge [3]
            Section {
                if let von = bezugszeitraumVon, let bis = bezugszeitraumBis {
                    LabeledContent("Zeitraum") {
                        Text("\(von.formatted(date: .abbreviated, time: .omitted)) – \(bis.formatted(date: .abbreviated, time: .omitted))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Gesamtbezug") {
                    Text("\(gesamtStrombezugsmenge.formatted()) kWh")
                        .monospacedDigit()
                }
                LabeledContent("Gesamtkosten") {
                    Text(gesamtRechnungsbetrag, format: .currency(code: "CHF"))
                        .monospacedDigit()
                }
            } header: {
                Text("Bisherige Bezüge (Stromrechnungen)")
            } footer: {
                Text("Summen über alle \(gemeinschaft.stromrechnungen?.count ?? 0) Stromrechnungen dieser Gemeinschaft.")
            }

            // MARK: Abschnitt: Bezugsparteien
            Section {
                ForEach((gemeinschaft.bezugsparteien ?? []).sorted(by: { $0.name < $1.name })) { partei in
                    NavigationLink(destination: BezugsparteiDetailView(gemeinschaft: gemeinschaft, partei: partei)) {
                        HStack {
                            Text(partei.name)
                            Spacer()
                            Text(abgerechnetBetragFuerPartei(partei), format: .currency(code: "CHF"))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                .onDelete(perform: bezugsparteiLoeschen)

                // Summen-Zeile
                let summeAnteile = (gemeinschaft.bezugsparteien ?? []).reduce(Decimal(0)) { $0 + $1.anteil }
                let summeAbgerechnet = (gemeinschaft.bezugsparteien ?? []).reduce(Decimal(0)) { $0 + abgerechnetBetragFuerPartei($1) }
                HStack {
                    Text("Summe")
                        .bold()
                    Spacer()
                    Text(summeAbgerechnet, format: .currency(code: "CHF"))
                        .bold()
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                NavigationLink(destination: BezugsparteiBearbeitenView(gemeinschaft: gemeinschaft, partei: nil)) {
                    Label("Neue Bezugspartei", systemImage: "person.badge.plus")
                }
            } header: {
                Text("Bezugsparteien")
            } footer: {
                Text("Summe der noch nicht abgerechneten Beträge pro Bezugspartei.")
            }
        }
        .navigationTitle(gemeinschaft.bezeichnung)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        zeigeStromrechnungen = true
                    } label: {
                        Label("Stromrechnungen", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Button {
                        zeigeStromabrechnungen = true
                    } label: {
                        Label("Stromabrechnungen", systemImage: "doc.plaintext.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        zeigeBearbeiten = true
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                } label: {
                    Label("Menü", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $zeigeStromrechnungen) {
            StromrechnungenListeView(gemeinschaft: gemeinschaft)
        }
        .sheet(isPresented: $zeigeStromabrechnungen) {
            StromabrechnungenListeView(gemeinschaft: gemeinschaft)
        }
        .sheet(isPresented: $zeigeBearbeiten) {
            StromgemeinschaftBearbeitenView(gemeinschaft: gemeinschaft)
        }
    }

    // MARK: Aktionen

    private func bezugsparteiLoeschen(at offsets: IndexSet) {
        let sortierte = (gemeinschaft.bezugsparteien ?? []).sorted(by: { $0.name < $1.name })
        for index in offsets {
            modelContext.delete(sortierte[index])
        }
    }
    
    /// Berechnet den abgerechneten Betrag für eine Bezugspartei
    /// (Summe Parteienabrechungen - Summe Parteienrechnungen)
    private func abgerechnetBetragFuerPartei(_ partei: Bezugspartei) -> Decimal {
        let summeAbrechnungen = (partei.parteienabrechungen ?? []).reduce(Decimal(0)) { $0 + $1.betrag }
        let summeRechnungen = (partei.parteienrechnungen ?? []).reduce(Decimal(0)) { $0 + $1.abgerechneterBetrag }
        return summeAbrechnungen - summeRechnungen
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
