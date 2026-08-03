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

    // MARK: - Formularfelder

    @State private var name = ""
    @State private var anteilText = ""

    // Adresse
    @State private var street = ""
    @State private var houseNumber = ""
    @State private var postalCode = ""
    @State private var city = ""
    @State private var countryCode = "CH"
    @State private var email = ""

    // MARK: - Berechnete Hilfsgrössen

    /// Summe der anderen Parteien (ohne die aktuell bearbeitete)
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
              let a = anteil, a >= 0 else { return false }
        return true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Name
                Section("Partei") {
                    TextField("Name der Bezugspartei", text: $name)
                        .textContentType(.organizationName)
                }

                // MARK: Adresse
                Section("Adresse") {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("Strasse", text: $street)
                            .textContentType(.streetAddressLine1)
                            .frame(maxWidth: .infinity)
                        TextField("Nr.", text: $houseNumber)
                            .textContentType(.streetAddressLine2)
                            .frame(width: 64)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("PLZ", text: $postalCode)
                            .textContentType(.postalCode)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                        TextField("Ort", text: $city)
                            .textContentType(.addressCity)
                            .frame(maxWidth: .infinity)
                    }
                    TextField("Ländercode (ISO 3166-1, z. B. CH)", text: $countryCode)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: countryCode) { _, newValue in
                            // Auf 2 Zeichen begrenzen und Grossbuchstaben erzwingen
                            countryCode = String(newValue.uppercased().prefix(2))
                        }
                }

                // MARK: Kontakt
                Section("Kontakt") {
                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // MARK: Anteil
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
                } header: {
                    Text("Anteil")
                } footer: {
                    Text("Bereits vergeben (andere Parteien): \(summeAndere.formatted()) %. Verbleibend: \((100 - summeAndere).formatted()) %.")
                }
            }
            .navigationTitle(partei == nil ? "Neue Bezugspartei" : "Bezugspartei bearbeiten")
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

    // MARK: - Hilfsmethoden

    private func vorbelegen() {
        guard let p = partei else { return }
        name = p.name
        anteilText = "\(p.anteil)"
        street = p.street
        houseNumber = p.houseNumber
        postalCode = p.postalCode
        city = p.city
        countryCode = p.countryCode
        email = p.email
    }

    private func speichern() {
        guard let a = anteil else { return }

        if let p = partei {
            p.name = name.trimmingCharacters(in: .whitespaces)
            p.anteil = a
            p.street = street.trimmingCharacters(in: .whitespaces)
            p.houseNumber = houseNumber.trimmingCharacters(in: .whitespaces)
            p.postalCode = postalCode.trimmingCharacters(in: .whitespaces)
            p.city = city.trimmingCharacters(in: .whitespaces)
            p.countryCode = countryCode.trimmingCharacters(in: .whitespaces)
            p.email = email.trimmingCharacters(in: .whitespaces)
        } else {
            let neu = Bezugspartei(
                name: name.trimmingCharacters(in: .whitespaces),
                anteil: a,
                street: street.trimmingCharacters(in: .whitespaces),
                houseNumber: houseNumber.trimmingCharacters(in: .whitespaces),
                postalCode: postalCode.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces),
                countryCode: countryCode.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                stromgemeinschaft: gemeinschaft
            )
            modelContext.insert(neu)
        }
        dismiss()
    }
}
