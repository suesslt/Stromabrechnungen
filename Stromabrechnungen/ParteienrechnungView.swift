//
//  ParteienrechnungView.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import SwiftUI
import SwissInvoice
import Score
import QuickLook

struct ParteienrechnungView: View {
    let rechnung: Parteienrechnung

    @State private var pdfURL: IdentifiableURL?
    @State private var mailKontext: MailKontext?
    @State private var zeigeMailNichtVerfuegbarAlert = false

    // MARK: - Berechnete Hilfsgrössen

    private var invoice: SwissInvoice? {
        rechnung.swissInvoice()
    }

    private var kreditor: Address? {
        rechnung.bezugspartei?.stromgemeinschaft?.kreditorAdresse
    }

    private var rechnungstitel: String {
        let von = rechnung.rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)
        let bis = rechnung.rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted)
        return "Stromabrechnung \(von) – \(bis)"
    }

    // MARK: - PDF erzeugen & anzeigen

    private var pdfDateiname: String {
        rechnungstitel
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "–", with: "-")
    }

    private func generateAndShowPDF() {
        guard let invoice else { return }
        let data = invoice.pdfData()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(pdfDateiname).pdf")
        try? data.write(to: url)
        pdfURL = IdentifiableURL(url: url)
    }

    // MARK: - Mail-Versand

    private var empfaengerEMail: String {
        rechnung.bezugspartei?.email.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func mailVorbereiten() {
        guard let invoice else { return }
        guard MailComposeView.canSendMail else {
            zeigeMailNichtVerfuegbarAlert = true
            return
        }
        let pdfData = invoice.pdfData()
        let body = """
        Guten Tag\(rechnung.bezugspartei.map { " \($0.name)" } ?? "")

        Anbei die Stromabrechnung für den Zeitraum \
        \(rechnung.rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \
        \(rechnung.rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted)).

        Freundliche Grüsse
        """
        mailKontext = MailKontext(
            empfaenger: empfaengerEMail.isEmpty ? [] : [empfaengerEMail],
            betreff: rechnungstitel,
            body: body,
            pdfData: pdfData,
            dateiname: "\(pdfDateiname).pdf"
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Kopf
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stromrechnung")
                        .font(.largeTitle.bold())
                    Text(
                        "\(rechnung.rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(rechnung.rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Divider()

                // MARK: Adressen (Kreditor / Debtor)
                HStack(alignment: .top, spacing: 32) {
                    // Kreditor
                    if let kreditor {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Von")
                                .font(.caption.uppercaseSmallCaps())
                                .foregroundStyle(.secondary)
                            Text(kreditor.displayName).bold()
                            if !kreditor.addressAddition1.isEmpty {
                                Text(kreditor.addressAddition1)
                            }
                            if !kreditor.addressAddition2.isEmpty {
                                Text(kreditor.addressAddition2)
                            }
                            Text("\(kreditor.street) \(kreditor.houseNumber)")
                            Text("\(kreditor.postalCode) \(kreditor.city)")
                            Text(kreditor.countryCode)
                        }
                        .font(.subheadline)
                    }

                    Spacer()

                    // Debtor
                    if let partei = rechnung.bezugspartei {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("An")
                                .font(.caption.uppercaseSmallCaps())
                                .foregroundStyle(.secondary)
                            Text(partei.name).bold()
                            Text("\(partei.street) \(partei.houseNumber)")
                            Text("\(partei.postalCode) \(partei.city)")
                            Text(partei.countryCode)
                        }
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                    }
                }

                Divider()

                // MARK: Rechnungsdetails
                VStack(spacing: 12) {
                    LabeledContent("Rechnungsdatum") {
                        Text(rechnung.rechnungsdatum, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Bezugsmenge") {
                        Text("\(rechnung.abgerechneteBezugsmenge.formatted()) kWh")
                            .monospacedDigit()
                    }
                    LabeledContent("Rechnungsbetrag") {
                        if let invoice {
                            Text(invoice.amount.formatted)
                                .monospacedDigit()
                                .bold()
                        }
                    }
                    if let gemeinschaft = rechnung.bezugspartei?.stromgemeinschaft {
                        LabeledContent("IBAN") {
                            Text(gemeinschaft.abrechnungskonto)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Status") {
                        Picker("Status", selection: Binding(
                            get: { rechnung.rechnungsstatus },
                            set: { rechnung.rechnungsstatus = $0 }
                        )) {
                            ForEach(Rechnungsstatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }
                .font(.subheadline)

                if invoice == nil {
                    ContentUnavailableView(
                        "Rechnung nicht verfügbar",
                        systemImage: "doc.text",
                        description: Text("Bitte prüfe die Kreditor-Adresse in den Stammdaten der Stromgemeinschaft sowie die IBAN.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle(rechnung.bezugspartei?.name ?? "Rechnung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    mailVorbereiten()
                } label: {
                    Label("Per E-Mail senden", systemImage: "envelope")
                }
                .disabled(invoice == nil)

                Button {
                    generateAndShowPDF()
                } label: {
                    Label("PDF anzeigen", systemImage: "doc.richtext")
                }
                .disabled(invoice == nil)
            }
        }
        .fullScreenCover(item: $pdfURL) { item in
            PDFPreviewView(url: item.url)
        }
        .sheet(item: $mailKontext) { ctx in
            MailComposeView(
                recipients: ctx.empfaenger,
                subject: ctx.betreff,
                body: ctx.body,
                attachmentData: ctx.pdfData,
                attachmentFilename: ctx.dateiname
            ) {
                mailKontext = nil
            }
            .ignoresSafeArea()
        }
        .alert("E-Mail nicht verfügbar", isPresented: $zeigeMailNichtVerfuegbarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Auf diesem Gerät ist kein Mail-Account konfiguriert. Bitte richte in der Mail-App ein Konto ein.")
        }
    }
}

// MARK: - Mail-Kontext (Sheet-Item)

private struct MailKontext: Identifiable {
    let id = UUID()
    let empfaenger: [String]
    let betreff: String
    let body: String
    let pdfData: Data
    let dateiname: String
}

// MARK: - Identifiable-Wrapper für URL

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - QuickLook PDF-Vorschau

private struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}
