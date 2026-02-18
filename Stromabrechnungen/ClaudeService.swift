//
//  ClaudeService.swift
//  Stromabrechnungen
//

import Foundation

// MARK: - Erkannte Rechnungsfelder (Antwort von Claude)

struct ErkannteStromrechnung: Decodable {
    var rechnungssteller: String
    var rechnungsdatum: String       // ISO-8601: "YYYY-MM-DD"
    var abrechnungszeitraumVon: String // ISO-8601: "YYYY-MM-DD"
    var abrechnungszeitraumBis: String // ISO-8601: "YYYY-MM-DD"
    var rechnungsbetrag: String       // Dezimalzahl als String, z.B. "123.45"
    var strombezugsmenge: String      // Dezimalzahl als String, z.B. "456.789"
}

// MARK: - Claude API Fehler

enum ClaudeServiceFehler: LocalizedError {
    case keinAPIKey
    case ungueltigeAntwort
    case httpFehler(Int, String)
    case jsonParseFehler(String)

    var errorDescription: String? {
        switch self {
        case .keinAPIKey:
            return "Kein Claude API-Key hinterlegt. Bitte in den Einstellungen erfassen."
        case .ungueltigeAntwort:
            return "Die Antwort von Claude konnte nicht verarbeitet werden."
        case .httpFehler(let code, let body):
            return "Claude API Fehler \(code): \(body)"
        case .jsonParseFehler(let detail):
            return "JSON-Fehler: \(detail)"
        }
    }
}

// MARK: - Claude Service

actor ClaudeService {

    static let shared = ClaudeService()

    private let apiKeyUserDefaultsKey = "claudeAPIKey"
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let modell = "claude-opus-4-5"

    // MARK: API-Key Verwaltung

    nonisolated var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyUserDefaultsKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyUserDefaultsKey) }
    }

    // MARK: Hauptmethode: PDF → ErkannteStromrechnung

    func erkenneFelderAusPDF(pdfData: Data) async throws -> ErkannteStromrechnung {
        let key = apiKey
        guard !key.isEmpty else { throw ClaudeServiceFehler.keinAPIKey }

        let base64PDF = pdfData.base64EncodedString()

        // Anfrage-Body nach Anthropic Messages API
        let body: [String: Any] = [
            "model": modell,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "document",
                            "source": [
                                "type": "base64",
                                "media_type": "application/pdf",
                                "data": base64PDF
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analysiere diese Stromrechnung und extrahiere folgende Felder.
                            Antworte NUR mit einem validen JSON-Objekt, ohne Erklärungen, \
                            ohne Markdown-Codeblöcke, nur reines JSON.

                            Felder:
                            - rechnungssteller: Name des Stromlieferanten
                            - rechnungsdatum: Datum der Rechnung im Format YYYY-MM-DD
                            - abrechnungszeitraumVon: Beginn des Abrechnungszeitraums im Format YYYY-MM-DD
                            - abrechnungszeitraumBis: Ende des Abrechnungszeitraums im Format YYYY-MM-DD
                            - rechnungsbetrag: Gesamtbetrag der Rechnung als Dezimalzahl (z.B. "123.45")
                            - strombezugsmenge: Bezogene Strommenge in kWh als Dezimalzahl (z.B. "456.789")

                            Falls ein Feld nicht eindeutig erkannt werden kann, verwende einen leeren String.
                            """
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeServiceFehler.ungueltigeAntwort
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeServiceFehler.httpFehler(http.statusCode, body)
        }

        // Anthropic-Antwort parsen → Text extrahieren
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let firstBlock = content.first,
            let text = firstBlock["text"] as? String
        else {
            throw ClaudeServiceFehler.ungueltigeAntwort
        }

        // Den Text-String als JSON dekodieren
        guard let jsonData = text.data(using: .utf8) else {
            throw ClaudeServiceFehler.jsonParseFehler("Text nicht als UTF-8 kodierbar")
        }

        do {
            let erkannt = try JSONDecoder().decode(ErkannteStromrechnung.self, from: jsonData)
            return erkannt
        } catch {
            throw ClaudeServiceFehler.jsonParseFehler(error.localizedDescription)
        }
    }
}
