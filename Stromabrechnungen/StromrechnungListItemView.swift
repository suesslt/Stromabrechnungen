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
                Text(rechnung.rechnungssteller)
                    .font(.headline)
                Text(
                    "\(rechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(rechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(rechnung.rechnungsdatum, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            // MARK: Kennzahlen
            HStack(spacing: 16) {
                Label {
                    Text(
                        "\(Self.mengenFormatter.string(from: rechnung.strombezugsmenge as NSDecimalNumber) ?? "") kWh"
                    )
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "bolt")
                        .foregroundStyle(.yellow)
                }
                .font(.subheadline)

                Label {
                    Text(
                        Self.chfFormatter.string(from: rechnung.rechnungsbetrag as NSDecimalNumber) ?? ""
                    )
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "francsign")
                        .foregroundStyle(.green)
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
