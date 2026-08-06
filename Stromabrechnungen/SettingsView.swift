//
//  SettingsView.swift
//  Stromabrechnungen
//

import SwiftUI

struct SettingsView: View {
    @State private var eingabe = ""
    @State private var zeigeKey = false
    @State private var gespeichert = false
    @State private var fehler: String?

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
                    let key = eingabe.trimmingCharacters(in: .whitespaces)
                    Task {
                        do {
                            try await ClaudeService.shared.setAPIKey(key)
                            fehler = nil
                            gespeichert = true
                            try? await Task.sleep(for: .seconds(2))
                            gespeichert = false
                        } catch {
                            fehler = "Der Key konnte nicht im Schlüsselbund gespeichert werden. Versuche es erneut; hilft das nicht, starte die App neu."
                        }
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

                if let fehler {
                    Text(fehler)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

            } header: {
                Text("Claude AI API-Key")
            } footer: {
                Text("Den API-Key erhältst du unter console.anthropic.com. Er wird ausschliesslich lokal auf diesem Gerät im Schlüsselbund gespeichert und nie weitergegeben.")
            }

            Section("Modell") {
                LabeledContent("Verwendetes Modell", value: "claude-opus-4-5")
            }
        }
        .navigationTitle("Einstellungen")
        .task {
            eingabe = await ClaudeService.shared.apiKey()
        }
    }
}

// MARK: - Vorschau

#Preview {
    NavigationStack {
        SettingsView()
    }
}
