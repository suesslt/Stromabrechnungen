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
    @State private var zeigeNeuAbrechnung = false
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

    /// [5] Summe Abrechnungsbeträge auf Stromabrechnungen
    private var gesamtAbrechnungsbetrag: Decimal {
        (gemeinschaft.stromabrechnungen ?? []).reduce(0) { $0 + $1.abrechnungsbetrag }
    }

    /// [4] Summe Abrechnungsbezugsmengen auf Stromabrechnungen
    private var gesamtAbrechnungsbezugsmenge: Decimal {
        (gemeinschaft.stromabrechnungen ?? []).reduce(0) { $0 + $1.abrechnungsbezugsmenge }
    }

    /// Nicht verrechneter Rechnungsbetrag ([1] - [5])
    private var nichtVerrechnetBetrag: Decimal {
        gesamtRechnungsbetrag - gesamtAbrechnungsbetrag
    }

    /// Nicht verrechnete Bezugsmenge ([2] - [4])
    private var nichtVerrechnetMenge: Decimal {
        gesamtStrombezugsmenge - gesamtAbrechnungsbezugsmenge
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
                Button {
                    zeigeStromrechnungen = true
                } label: {
                    Label("Alle Stromrechnungen anzeigen", systemImage: "doc.text.magnifyingglass")
                }
            } header: {
                Text("Bisherige Bezüge (Stromrechnungen)")
            } footer: {
                Text("Summen über alle \(gemeinschaft.stromrechnungen?.count ?? 0) Stromrechnungen dieser Gemeinschaft.")
            }

            // MARK: Abschnitt: Nicht verrechnete Bezüge
            Section {
                LabeledContent("Nicht verrechnete Bezugsmenge") {
                    Text("\(nichtVerrechnetMenge.formatted()) kWh")
                        .monospacedDigit()
                        .foregroundStyle(nichtVerrechnetMenge > 0 ? .orange : .secondary)
                }
                LabeledContent("Nicht verrechneter Betrag") {
                    Text(nichtVerrechnetBetrag, format: .currency(code: "CHF"))
                        .monospacedDigit()
                        .foregroundStyle(nichtVerrechnetBetrag > 0 ? .orange : .secondary)
                }
                Button {
                    zeigeStromabrechnungen = true
                } label: {
                    Label("Alle Stromabrechnungen anzeigen", systemImage: "doc.plaintext.fill")
                }
            } header: {
                Text("Nicht verrechnete Bezüge")
            } footer: {
                Text("Differenz zwischen Stromrechnungen und Stromabrechnungen.")
            }

            // MARK: Abschnitt: Bezugsparteien
            Section {
                ForEach((gemeinschaft.bezugsparteien ?? []).sorted(by: { $0.name < $1.name })) { partei in
                    NavigationLink(destination: BezugsparteiDetailView(gemeinschaft: gemeinschaft, partei: partei)) {
                        HStack {
                            Text(partei.name)
                            Spacer()
                            Text("\(partei.anteil.formatted()) %")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                .onDelete(perform: bezugsparteiLoeschen)

                // Summen-Zeile
                let summeAnteile = (gemeinschaft.bezugsparteien ?? []).reduce(Decimal(0)) { $0 + $1.anteil }
                HStack {
                    Text("Summe")
                        .bold()
                    Spacer()
                    Text("\(summeAnteile.formatted()) %")
                        .bold()
                        .foregroundStyle(summeAnteile == 100 ? .green : .red)
                }

                NavigationLink(destination: BezugsparteiBearbeitenView(gemeinschaft: gemeinschaft, partei: nil)) {
                    Label("Neue Bezugspartei", systemImage: "person.badge.plus")
                }
            } header: {
                Text("Bezugsparteien")
            } footer: {
                Text("Die Summe der Anteile muss 100 % betragen.")
            }

            // MARK: Neue Stromabrechnung erstellen
            Section {
                Button {
                    erstelleStromabrechnung()
                } label: {
                    Label("Neue Stromabrechnung erstellen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .disabled(
                    nichtVerrechnetMenge <= 0 ||
                    (gemeinschaft.bezugsparteien ?? []).isEmpty ||
                    (gemeinschaft.bezugsparteien ?? []).reduce(Decimal(0)) { $0 + $1.anteil } != 100
                )
            } footer: {
                let summe = (gemeinschaft.bezugsparteien ?? []).reduce(Decimal(0)) { $0 + $1.anteil }
                if summe != 100 {
                    Text("Die Anteile der Bezugsparteien müssen exakt 100 % ergeben (aktuell: \(summe.formatted()) %).")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(gemeinschaft.bezeichnung)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { zeigeBearbeiten = true }
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

    private func erstelleStromabrechnung() {
        let sortiertParteien = (gemeinschaft.bezugsparteien ?? []).sorted(by: { $0.name < $1.name })

        // Voraussetzung: Die Anteile aller Bezugsparteien müssen exakt 100 % ergeben.
        // Andernfalls wäre die proportionale Aufteilung rechnerisch falsch.
        let summeAnteile = sortiertParteien.reduce(Decimal(0)) { $0 + $1.anteil }
        guard summeAnteile == 100 else { return }

        // Werte vor dem Insert sichern – nach modelContext.insert() würden die
        // berechneten Properties nichtVerrechnetBetrag/-Menge sofort 0 zurückgeben,
        // weil die neue Abrechnung die Differenz bereits ausgleicht.
        let gesamtBetrag = nichtVerrechnetBetrag
        let gesamtMenge  = nichtVerrechnetMenge

        // Voraussetzung: Es gibt einen offenen (noch nicht abgerechneten) Betrag.
        guard gesamtBetrag > 0, gesamtMenge > 0 else { return }

        // Zeitraum: Frühestes Von / Spätestes Bis über alle Stromrechnungen.
        let rechnungen = gemeinschaft.stromrechnungen ?? []
        let zeitraumVon = rechnungen.map(\.abrechnungszeitraumVon).min() ?? .now
        let zeitraumBis = rechnungen.map(\.abrechnungszeitraumBis).max() ?? .now

        let abrechnung = Stromabrechnung(
            datum: .now,
            abrechnungszeitraumVon: zeitraumVon,
            abrechnungszeitraumBis: zeitraumBis,
            abrechnungsbetrag: gesamtBetrag,
            abrechnungsbezugsmenge: gesamtMenge,
            stromgemeinschaft: gemeinschaft
        )
        modelContext.insert(abrechnung)

        // Parteienabrechungen proportional zu den Anteilen aufteilen (Basis: 100 %).
        // Der letzte Eintrag erhält den verbleibenden Rest, damit Betrag und Menge
        // in der Summe exakt übereinstimmen und keine Rundungsdifferenzen entstehen.
        var restBetrag = gesamtBetrag
        var restMenge  = gesamtMenge

        for (idx, partei) in sortiertParteien.enumerated() {
            let istLetzte = idx == sortiertParteien.count - 1

            let parteiBetrag: Decimal
            let parteiBezugsmenge: Decimal

            if istLetzte {
                parteiBetrag      = restBetrag
                parteiBezugsmenge = restMenge
            } else {
                parteiBetrag      = (gesamtBetrag * partei.anteil / 100).rounded(scale: 2)
                parteiBezugsmenge = (gesamtMenge  * partei.anteil / 100).rounded(scale: 3)
                restBetrag -= parteiBetrag
                restMenge  -= parteiBezugsmenge
            }

            let pa = Parteienabrechnung(
                betrag: parteiBetrag,
                bezugsmenge: parteiBezugsmenge,
                stromabrechnung: abrechnung,
                bezugspartei: partei
            )
            modelContext.insert(pa)
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
