//
//  ClaudeService.swift
//  Stromabrechnungen
//

import Foundation
import ScoreAI
import ScoreKeychain

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

// MARK: - Claude Service

actor ClaudeService {

    static let shared = ClaudeService()

    private let apiKeyUserDefaultsKey = "claudeAPIKey"
    private let modell = "claude-opus-4-5"

    // ScoreKeychain (score v2.1.0, 2026-08-06): Der API-Key lag zuvor als Klartext in
    // den UserDefaults — eine Datei, die jedes Backup mitnimmt. Jetzt Schlüsselbund;
    // ein Altbestand in den UserDefaults wird beim ersten Lesen einmalig umgezogen.
    private let keyStore = KeychainSecretStore(service: "suessli.Stromabrechnungen")
    private let keychainAccount = "claudeAPIKey"

    // MARK: API-Key Verwaltung

    func apiKey() async -> String {
        if let key = try? await keyStore.secret(for: keychainAccount), !key.isEmpty {
            return key
        }
        // Einmalige Migration des UserDefaults-Altbestands in den Schlüsselbund.
        if let legacy = UserDefaults.standard.string(forKey: apiKeyUserDefaultsKey), !legacy.isEmpty {
            try? await keyStore.setSecret(legacy, for: keychainAccount)
            UserDefaults.standard.removeObject(forKey: apiKeyUserDefaultsKey)
            return legacy
        }
        return ""
    }

    func setAPIKey(_ key: String) async throws {
        try await keyStore.setSecret(key, for: keychainAccount)
        UserDefaults.standard.removeObject(forKey: apiKeyUserDefaultsKey)
    }

    // MARK: Hauptmethode: PDF → ErkannteStromrechnung

    func erkenneFelderAusPDF(pdfData: Data) async throws -> ErkannteStromrechnung {
        let key = await apiKey()
        guard !key.isEmpty else { throw AIProviderError.missingAPIKey }

        let prompt = """
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

        let client = ClaudeClient(apiKey: key)
        return try await client.generateJSON(
            ErkannteStromrechnung.self,
            system: nil,
            user: prompt,
            attachments: [.documentPDF(pdfData)],
            config: ClaudeRequestConfig(model: modell, maxTokens: 1024, timeout: 120)
        )
    }
}
