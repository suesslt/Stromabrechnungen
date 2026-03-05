//
//  ParteienrechnungView.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import SwiftUI
import SwissInvoice
import QuickLook

struct ParteienrechnungView: View {
    let rechnung: Parteienrechnung

    @State private var pdfURL: IdentifiableURL?

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

    private func generateAndShowPDF() {
        guard let invoice else { return }
        let data = invoice.pdfData()
        let filename = rechnungstitel
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "–", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).pdf")
        try? data.write(to: url)
        pdfURL = IdentifiableURL(url: url)
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
                            Text(kreditor.name).bold()
                            if !kreditor.addressAddition.isEmpty {
                                Text(kreditor.addressAddition)
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
            ToolbarItem(placement: .primaryAction) {
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
    }
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
