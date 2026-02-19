//
//  ParteienrechnungView.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import SwiftUI

struct ParteienrechnungView: View {
    let parteienabrechnung: Parteienabrechnung

    @AppStorage("kreditorAdresse") private var kreditor: QRAddress = .empty

    // MARK: - Berechnete Hilfsgrössen

    private var bill: QRBill? {
        QRBill.fromParteienabrechnung(
            parteienabrechnung,
            creditor: kreditor,
            additionalInfo: rechnungstitel
        )
    }

    private var rechnungstitel: String {
        let zeitraum = parteienabrechnung.stromabrechnung.map {
            "\($0.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \($0.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
        } ?? ""
        return "Stromabrechnung \(zeitraum)"
    }

    private static let chfFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CHF"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Kopf
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stromabrechnung")
                        .font(.largeTitle.bold())
                    if let abrechnung = parteienabrechnung.stromabrechnung {
                        Text(
                            "\(abrechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(abrechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // MARK: Adressen (Kreditor / Debtor)
                HStack(alignment: .top, spacing: 32) {
                    // Kreditor
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Von")
                            .font(.caption.uppercaseSmallCaps())
                            .foregroundStyle(.secondary)
                        Text(kreditor.name).bold()
                        Text("\(kreditor.street) \(kreditor.houseNumber)")
                        Text("\(kreditor.postalCode) \(kreditor.city)")
                        Text(kreditor.countryCode)
                    }
                    .font(.subheadline)

                    Spacer()

                    // Debtor
                    if let partei = parteienabrechnung.bezugspartei {
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
                    LabeledContent("Bezugsmenge") {
                        Text("\(parteienabrechnung.bezugsmenge.formatted()) kWh")
                            .monospacedDigit()
                    }
                    LabeledContent("Rechnungsbetrag") {
                        Text(
                            Self.chfFormatter.string(
                                from: parteienabrechnung.betrag as NSDecimalNumber
                            ) ?? ""
                        )
                        .monospacedDigit()
                        .bold()
                    }
                    if let gemeinschaft = parteienabrechnung.stromabrechnung?.stromgemeinschaft {
                        LabeledContent("IBAN") {
                            Text(gemeinschaft.abrechnungskonto)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.subheadline)

                Divider()

                // MARK: QR-Rechnung
                if let bill {
                    VStack(alignment: .center, spacing: 16) {
                        Text("Zahlteil")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .top, spacing: 24) {
                            // QR-Code
                            QRCodeView(payload: bill.generatePayload(), size: 160)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )

                            // Betrag & Währung
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Währung")
                                        .font(.caption.uppercaseSmallCaps())
                                        .foregroundStyle(.secondary)
                                    Text(bill.currency)
                                        .font(.subheadline.bold())
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Betrag")
                                        .font(.caption.uppercaseSmallCaps())
                                        .foregroundStyle(.secondary)
                                    Text(
                                        Self.chfFormatter.string(
                                            from: parteienabrechnung.betrag as NSDecimalNumber
                                        ) ?? ""
                                    )
                                    .font(.title3.bold())
                                    .monospacedDigit()
                                }
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // Fehlermeldung wenn Daten unvollständig
                    ContentUnavailableView(
                        "QR-Code nicht verfügbar",
                        systemImage: "qrcode.viewfinder",
                        description: Text("Bitte prüfe die Kreditor-Adresse in den Einstellungen sowie die IBAN der Stromgemeinschaft.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle(parteienabrechnung.bezugspartei?.name ?? "Rechnung")
        .navigationBarTitleDisplayMode(.inline)
    }
}
