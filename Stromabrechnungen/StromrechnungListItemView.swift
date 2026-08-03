//
//  StromrechnungListItemView.swift
//  Stromabrechnungen
//

import SwiftUI

struct StromrechnungListItemView: View {
    let rechnung: Stromrechnung

    private static let chfFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CHF"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let mengenFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // MARK: Kopfzeile
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    "\(rechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(rechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.headline)
                .foregroundStyle(.primary)
                HStack {
                    Text(rechnung.rechnungsdatum, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rechnung.rechnungssteller)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 6)

            VStack(spacing: 2) {
                LabeledContent("Lieferung") {
                    Text("\(Self.mengenFormatter.string(from: rechnung.strombezugsmenge as NSDecimalNumber) ?? "") kWh")
                        .monospacedDigit()
                }
                LabeledContent("Rechnungsbetrag") {
                    Text(Self.chfFormatter.string(from: rechnung.rechnungsbetrag as NSDecimalNumber) ?? "")
                        .monospacedDigit()
                }
                if rechnung.gutschrift > 0 {
                    LabeledContent("Gutschrift") {
                        Text(Self.chfFormatter.string(from: rechnung.gutschrift as NSDecimalNumber) ?? "")
                            .monospacedDigit()
                    }
                    LabeledContent("Verrechenbar") {
                        Text(Self.chfFormatter.string(from: rechnung.verrechenbarerBetrag as NSDecimalNumber) ?? "")
                            .monospacedDigit()
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
