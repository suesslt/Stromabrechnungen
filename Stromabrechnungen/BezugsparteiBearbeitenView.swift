//
//  BezugsparteiBearbeitenView.swift
//  Stromabrechnungen
//
import SwiftUI
import SwiftData

struct BezugsparteiBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gemeinschaft: Stromgemeinschaft

    /// `nil` = Neu anlegen
    var partei: Bezugspartei?

    @State private var name = ""
    @State private var anteilText = ""
    @State private var validierungsfehler: String?

    // Summe der anderen Parteien (ohne die aktuell bearbeitete)
    private var summeAndere: Decimal {
        (gemeinschaft.bezugsparteien ?? [])
            .filter { $0.persistentModelID != partei?.persistentModelID }
            .reduce(0) { $0 + $1.anteil }
    }

    private var anteil: Decimal? {
        Decimal(string: anteilText.replacingOccurrences(of: ",", with: "."))
    }

    private var eingabeGueltig: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let a = anteil, a > 0 else { return false }
        return summeAndere + a <= 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Partei") {
                    TextField("Name der Bezugspartei", text: $name)
                }
                Section {
                    TextField("Anteil (%)", text: $anteilText)
                        .keyboardType(.decimalPad)
                    if let a = anteil {
                        let neueSumme = summeAndere + a
                        LabeledContent("Neue Gesamtsumme") {
                            Text("\(neueSumme.formatted()) %")
                                .foregroundStyle(neueSumme == 100 ? .green : (neueSumme > 100 ? .red : .orange))
                                .bold()
                        }
                    }
                    if let fehler = validierungsfehler {
                        Text(fehler)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Anteil")
                } footer: {
                    Text("Bereits vergeben (andere Parteien): \(summeAndere.formatted()) %. Verbleibend: \((100 - summeAndere).formatted()) %.")
                }
            }
            .navigationTitle(partei == nil ? "Neue Bezugspartei" : "Anteil bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(!eingabeGueltig)
                }
            }
            .onAppear { vorbelegen() }
        }
    }

    private func vorbelegen() {
        guard let p = partei else { return }
        name = p.name
        anteilText = "\(p.anteil)"
    }

    private func speichern() {
        guard let a = anteil else { return }
        let neueSumme = summeAndere + a
        guard neueSumme <= 100 else {
            validierungsfehler = "Die Summe der Anteile würde \(neueSumme.formatted()) % ergeben. Maximum ist 100 %."
            return
        }

        if let p = partei {
            p.name = name.trimmingCharacters(in: .whitespaces)
            p.anteil = a
        } else {
            let neu = Bezugspartei(
                name: name.trimmingCharacters(in: .whitespaces),
                anteil: a,
                stromgemeinschaft: gemeinschaft
            )
            modelContext.insert(neu)
        }
        dismiss()
    }
}
