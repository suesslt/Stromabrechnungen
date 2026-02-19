# Stromabrechnungen

**Stromabrechnungen** ist eine iOS/macOS-App für die einfache, transparente Verwaltung von Stromkosten in Energiegemeinschaften – von der Eingangsrechnung bis zur fertigen, druckbaren Rechnung mit Swiss-QR-Code.

---

## Für wen ist diese App?

Die App richtet sich an Verwaltungen, Eigentümergemeinschaften oder private Zusammenschlüsse, die gemeinsam Strom beziehen und die Kosten anteilig auf mehrere Parteien (Mieter, Eigentümer, Wohneinheiten) aufteilen müssen – z. B. im Rahmen einer **Eigenverbrauchsgemeinschaft (EVG)** oder eines **Zusammenschlusses zum Eigenverbrauch (ZEV)** in der Schweiz.

---

## Was die App kann

### Energiegemeinschaften verwalten
Legen Sie beliebig viele Stromgemeinschaften an, jeweils mit Name, Kontonummer und optionalem Logo. Die App zeigt auf einen Blick den gesamten Rechnungsbetrag, bereits verteilte und noch offene Beträge sowie alle Bezugsparteien.

### Stromrechnungen erfassen – manuell oder per KI
Eingangsrechnungen des Stromversorgers lassen sich **manuell eingeben** oder direkt aus einem **PDF importieren**. Beim PDF-Import analysiert die integrierte **Claude KI (Anthropic)** das Dokument automatisch und extrahiert:

- Lieferantenname
- Rechnungsdatum und Abrechnungszeitraum
- Rechnungsbetrag
- Strommenge (kWh)

Die erkannten Werte werden zur Prüfung angezeigt und können vor dem Speichern korrigiert werden.

### Kosten automatisch aufteilen
Mit einem Klick verteilt die App den Rechnungsbetrag proportional auf alle Bezugsparteien gemäß ihrer **prozentualen Anteile**. Die Rundung erfolgt dabei kaufmännisch korrekt – der letzte Empfänger erhält den Restbetrag, sodass die Summe immer exakt aufgeht.

### Rechnungen an Parteien ausstellen
Für jede Bezugspartei lässt sich eine professionelle Rechnung erstellen, die:

- Absender- und Empfängeradresse enthält
- Betrag und Zeitraum ausweist
- einen **Swiss-QR-Code** für die einfache elektronische Zahlung enthält

### Zahlungsstatus verfolgen
Jede Rechnung hat einen Zahlungsstatus (**offen**, **bezahlt**, **storniert**), der jederzeit aktualisiert werden kann. So behalten Sie den Überblick, welche Parteien noch ausstehende Beträge haben.

### Drucken und teilen
Die Rechnungsansicht ist druckfertig gestaltet. Der Swiss-QR-Code ermöglicht es den Empfängern, die Zahlung direkt im E-Banking zu scannen – ohne manuelle Dateneingabe.

---

## Vorteile auf einen Blick

| Vorteil | Details |
|---|---|
| **KI-gestützter PDF-Import** | Stromrechnungen müssen nicht mehr manuell abgetippt werden – die KI liest die relevanten Felder automatisch aus |
| **Fehlerfreie Kostenverteilung** | Die automatische Berechnung mit korrekter Rundungslogik verhindert Rechenfehler bei der Aufteilung |
| **Swiss-QR-Code-Unterstützung** | Rechnungen entsprechen dem aktuellen Schweizer Standard für elektronische Zahlungen |
| **Doppelerfassung verhindern** | Die App warnt, wenn ein Abrechnungszeitraum bereits erfasst wurde |
| **iCloud-Synchronisation** | Daten werden automatisch über CloudKit gesichert und auf allen eigenen Geräten synchronisiert |
| **Offline nutzbar** | Die App funktioniert vollständig ohne Internetverbindung; Synchronisation erfolgt automatisch, sobald eine Verbindung besteht |
| **Präzise Finanzberechnung** | Alle Berechnungen verwenden den `Decimal`-Typ (kein Gleitkomma-Rundungsfehler) |
| **Transparenz** | Jede Partei sieht genau, welche Beträge ihr zugewiesen wurden und welche Rechnungen offen sind |
| **Alles in einer App** | Von der Eingangsrechnung über die Kostenverteilung bis zur ausgedruckten Parteirechnung – kein Wechsel zwischen Tabellen, PDF-Tools und Zahlungssoftware nötig |

---

## Erster Einstieg

### 1. Einstellungen konfigurieren

Öffnen Sie **Einstellungen** (Zahnrad-Symbol) und hinterlegen Sie:

- **Claude API-Schlüssel** – wird für den automatischen PDF-Import benötigt. Den Schlüssel erhalten Sie unter [console.anthropic.com](https://console.anthropic.com). Er wird ausschließlich lokal auf Ihrem Gerät gespeichert.
- **Gläubigeradresse** – Ihre Adresse und IBAN, die auf den ausgestellten Rechnungen und QR-Codes erscheinen.

### 2. Stromgemeinschaft anlegen

Tippen Sie auf dem Startbildschirm auf **+** und vergeben Sie einen Namen sowie eine Kontonummer für Ihre Gemeinschaft.

### 3. Bezugsparteien hinzufügen

Wechseln Sie in die Gemeinschaftsdetails und fügen Sie alle Parteien mit vollständiger Adresse und ihrem **prozentualen Anteil** hinzu. Die Summe aller Anteile muss genau **100 %** ergeben.

### 4. Stromrechnungen erfassen

Tippen Sie auf **Stromrechnungen anzeigen** und fügen Sie neue Eingangsrechnungen hinzu:
- **PDF importieren** – Wählen Sie eine PDF-Datei aus; die KI extrahiert die Daten automatisch.
- **Manuell erfassen** – Geben Sie alle Felder selbst ein.

### 5. Abrechnung erstellen

In den Gemeinschaftsdetails tippen Sie auf **Neue Stromabrechnung erstellen**. Die App verteilt den gesamten unverteilten Betrag automatisch auf alle Parteien.

### 6. Rechnungen ausstellen und versenden

Öffnen Sie eine Bezugspartei und tippen Sie auf **Neue Rechnung erstellen**. Die Rechnung ist sofort druckbereit und enthält einen Swiss-QR-Code.

---

## Datenschutz und Datensicherheit

- Der Claude API-Schlüssel wird **nur lokal** in den App-Einstellungen gespeichert.
- PDF-Dokumente werden zur Analyse direkt an die Claude-API von Anthropic gesendet. Es werden keine Daten an Drittanbieter weitergegeben.
- Alle weiteren Daten (Rechnungen, Parteien, Beträge) bleiben ausschließlich auf Ihrem Gerät und in Ihrer privaten iCloud.

---

## Technische Anforderungen

- **iOS 17** oder neuer (iPhone/iPad)
- **macOS 14 Sonoma** oder neuer (Mac)
- iCloud-Account für die Datensynchronisation (optional)
- Claude API-Schlüssel für den PDF-Import (optional, manuelle Eingabe ist immer möglich)
