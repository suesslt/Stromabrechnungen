//
//  SettingsView.swift
//  Stromabrechnungen
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("KI", systemImage: "cpu") {
                KISettingsView()
            }
            Tab("Adresse Kreditor", systemImage: "building.2") {
                KreditorAdresseSettingsView()
            }
        }
        .navigationTitle("Einstellungen")
    }
}

// MARK: - Tab 1: KI-Einstellungen

private struct KISettingsView: View {
    @AppStorage("claudeAPIKey") private var claudeAPIKey = ""
    @State private var eingabe = ""
    @State private var zeigeKey = false
    @State private var gespeichert = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Group {
                        if zeigeKey {
                            TextField("sk-ant-…", text: $eingabe)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-ant-…", text: $eingabe)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    Button {
                        zeigeKey.toggle()
                    } label: {
                        Image(systemName: zeigeKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    claudeAPIKey = eingabe.trimmingCharacters(in: .whitespaces)
                    ClaudeService.shared.apiKey = claudeAPIKey
                    gespeichert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        gespeichert = false
                    }
                } label: {
                    HStack {
                        Text("Speichern")
                        if gespeichert {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .disabled(eingabe.trimmingCharacters(in: .whitespaces).isEmpty)

            } header: {
                Text("Claude AI API-Key")
            } footer: {
                Text("Den API-Key erhältst du unter console.anthropic.com. Er wird ausschliesslich lokal auf diesem Gerät in den UserDefaults gespeichert und nie weitergegeben.")
            }

            Section("Modell") {
                LabeledContent("Verwendetes Modell", value: "claude-opus-4-5")
            }
        }
        .onAppear {
            eingabe = claudeAPIKey
        }
    }
}

// MARK: - Tab 2: Kreditor-Adresse

private struct KreditorAdresseSettingsView: View {
    @AppStorage("kreditorAdresse") private var kreditorAdresse = QRAddress.empty

    var body: some View {
        Form {
            Section {
                TextField("Firma / Name", text: $kreditorAdresse.name)
                    .textContentType(.organizationName)
            } header: {
                Text("Name")
            }

            Section {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("Strasse", text: $kreditorAdresse.street)
                        .textContentType(.streetAddressLine1)
                        .frame(maxWidth: .infinity)
                    TextField("Nr.", text: $kreditorAdresse.houseNumber)
                        .textContentType(.streetAddressLine2)
                        .frame(width: 64)
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("PLZ", text: $kreditorAdresse.postalCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .frame(width: 80)
                    TextField("Ort", text: $kreditorAdresse.city)
                        .textContentType(.addressCity)
                        .frame(maxWidth: .infinity)
                }
                TextField("Ländercode (z. B. CH)", text: $kreditorAdresse.countryCode)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: kreditorAdresse.countryCode) { _, newValue in
                        kreditorAdresse.countryCode = String(newValue.uppercased().prefix(2))
                    }
            } header: {
                Text("Adresse")
            } footer: {
                Text("Zweistelliger Ländercode gemäss ISO 3166-1 (z. B. CH, DE, AT).")
            }
        }
        .navigationTitle("Adresse Kreditor")
    }
}

// MARK: - Vorschau

#Preview {
    NavigationStack {
        SettingsView()
    }
}
