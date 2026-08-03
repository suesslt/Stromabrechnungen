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
    var gutschrift: String            // Dezimalzahl als String, z.B. "12.50". "0" wenn keine Gutschrift.
    var strombezugsmenge: String      // Dezimalzahl als String, z.B. "456.789"

    private enum CodingKeys: String, CodingKey {
        case rechnungssteller, rechnungsdatum, abrechnungszeitraumVon, abrechnungszeitraumBis
        case rechnungsbetrag, gutschrift, strombezugsmenge
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rechnungssteller = try c.decode(String.self, forKey: .rechnungssteller)
        rechnungsdatum = try c.decode(String.self, forKey: .rechnungsdatum)
        abrechnungszeitraumVon = try c.decode(String.self, forKey: .abrechnungszeitraumVon)
        abrechnungszeitraumBis = try c.decode(String.self, forKey: .abrechnungszeitraumBis)
        rechnungsbetrag = try c.decode(String.self, forKey: .rechnungsbetrag)
        // Toleriert fehlende Gutschrift in der Antwort (alte Modelle, unklare Rechnungen).
        gutschrift = (try? c.decode(String.self, forKey: .gutschrift)) ?? "0"
        strombezugsmenge = try c.decode(String.self, forKey: .strombezugsmenge)
    }
}

// MARK: - Claude API Fehler

enum ClaudeServiceFehler: LocalizedError {
    case keinAPIKey
    case ungueltigeAntwort
    case httpFehler(Int, String)
    case jsonParseFehler(String)
    case netzwerkFehler(String)

    var errorDescription: String? {
        switch self {
        case .keinAPIKey:
            return "Kein Claude API-Key hinterlegt. Bitte in den Einstellungen erfassen."
        case .ungueltigeAntwort:
            return "Die Antwort von Claude konnte nicht verarbeitet werden."
        case .httpFehler(let code, _):
            return Self.benutzerfreundlicheMeldung(fuerStatusCode: code)
        case .jsonParseFehler(let detail):
            return "Die KI-Antwort konnte nicht verarbeitet werden: \(detail)"
        case .netzwerkFehler(let detail):
            return "Netzwerkfehler: \(detail)"
        }
    }

    /// Liefert eine verständliche Fehlermeldung je nach HTTP-Statuscode.
    private static func benutzerfreundlicheMeldung(fuerStatusCode code: Int) -> String {
        switch code {
        case 401:
            return "Ungültiger API-Key. Bitte in den Einstellungen prüfen."
        case 403:
            return "Zugriff verweigert. Bitte API-Key und Berechtigungen prüfen."
        case 429:
            return "Zu viele Anfragen. Bitte warte einen Moment und versuche es erneut."
        case 500:
            return "Interner Serverfehler bei Claude. Bitte versuche es in wenigen Minuten erneut."
        case 502:
            return "Claude API ist vorübergehend nicht erreichbar (502 Bad Gateway). Bitte versuche es in wenigen Minuten erneut."
        case 503:
            return "Claude API ist vorübergehend überlastet (503). Bitte versuche es in wenigen Minuten erneut."
        case 529:
            return "Claude API ist überlastet (529). Bitte versuche es später erneut."
        default:
            return "Claude API Fehler (\(code)). Bitte versuche es später erneut."
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
                            - gutschrift: Auf der Rechnung ausgewiesene Gutschrift / Vergütung in CHF \
                              (z.B. für eingespeisten Strom oder Rückvergütungen). "0" wenn keine Gutschrift vorhanden.
                            - strombezugsmenge: Bezogene Strommenge in kWh als Dezimalzahl (z.B. "456.789")

                            Falls ein Feld nicht eindeutig erkannt werden kann, verwende einen leeren String \
                            (bei der Gutschrift "0").
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
        request.timeoutInterval = 120 // 2 Minuten Timeout für grosse PDFs
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw ClaudeServiceFehler.netzwerkFehler("Zeitüberschreitung – bitte versuche es erneut.")
            case .notConnectedToInternet, .networkConnectionLost:
                throw ClaudeServiceFehler.netzwerkFehler("Keine Internetverbindung.")
            default:
                throw ClaudeServiceFehler.netzwerkFehler(error.localizedDescription)
            }
        }

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
