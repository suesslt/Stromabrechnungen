//
//  StromabrechnungListItemView.swift
//  Stromabrechnungen
//

import Score
import SwiftUI

struct StromabrechnungListItemView: View {
    let abrechnung: Stromabrechnung

    @State private var aufgeklappt = false

    private static let mengenFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Kopfzeile
            VStack(alignment: .leading, spacing: 2) {
                Text(abrechnung.datum, style: .date)
                    .font(.headline)
                Text(
                    "\(abrechnung.abrechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)) – \(abrechnung.abrechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)

            // MARK: Kennzahlen
            HStack(spacing: 16) {
                Text(
                    "\(Self.mengenFormatter.string(from: abrechnung.abrechnungsbezugsmenge as NSDecimalNumber) ?? "") kWh"
                )
                .monospacedDigit()
                .foregroundStyle(.primary)

                Text(Money.of(.chf, abrechnung.abrechnungsbetrag).formatted)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }

            // MARK: Parteienabrechungen (aufklappbar)
            let parteien = (abrechnung.parteienabrechungen ?? [])
                .sorted { ($0.bezugspartei?.name ?? "") < ($1.bezugspartei?.name ?? "") }

            if !parteien.isEmpty {
                Divider()
                    .padding(.top, 10)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        aufgeklappt.toggle()
                    }
                } label: {
                    HStack {
                        Text("Parteienabrechungen (\(parteien.count))")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(aufgeklappt ? 90 : 0))
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                if aufgeklappt {
                    Divider()
                    VStack(spacing: 0) {
                        ForEach(Array(parteien.enumerated()), id: \.element.id) { idx, pa in
                            HStack {
                                Text(pa.bezugspartei?.name ?? "–")
                                    .font(.subheadline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(
                                        "\(Self.mengenFormatter.string(from: pa.bezugsmenge as NSDecimalNumber) ?? "") kWh"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    Text(Money.of(.chf, pa.betrag).formatted)
                                        .font(.subheadline)
                                        .monospacedDigit()
                                }
                            }
                            .padding(.vertical, 8)

                            if idx < parteien.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
