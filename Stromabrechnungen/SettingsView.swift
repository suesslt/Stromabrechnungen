//
//  SettingsView.swift
//  Stromabrechnungen
//

import SwiftUI

struct SettingsView: View {
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
        .navigationTitle("Einstellungen")
        .onAppear {
            eingabe = claudeAPIKey
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
