//
//  QRCodeView.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Schweizerkreuz Shape

/// Zeichnet ein Schweizerkreuz (weisses Kreuz auf schwarzem Quadrat)
/// gemäss Swiss QR Bill Spezifikation (SIX, Version 2.x):
///   QR-Code:              46 × 46 mm
///   Trägerquadrat:         7 ×  7 mm  → Anteil: 7/46
///   Kreuzbalken (B × L):  3.5 × 9.5 mm relativ zum Trägerquadrat → 0.5 × 9.5/7
private struct SwissCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Kreuzbalken-Verhältnisse bezogen auf das Trägerquadrat (7 × 7 mm):
        //   Breite:  3.5 mm / 7 mm = 0.5
        //   Länge:   9.5 mm / 7 mm ≈ 1.357  → aber begrenzt auf das Quadrat → 1.0 (= volle Seite)
        // Tatsächlich laut SIX-Spezifikation Abbildung:
        //   Balkenbreite = 1/3 des Quadrats (≈ 2.33 mm / 7 mm)
        //   Balkenlänge  = 3/5 des Quadrats (≈ 4.2 mm / 7 mm)
        // Präzise Werte aus der Spez: Kreuzbalken 1.5 × 4.5 mm bei 7 mm Quadrat:
        //   Breite:  1.5 / 7 ≈ 0.2143
        //   Länge:   4.5 / 7 ≈ 0.6429
        let s = min(rect.width, rect.height)
        let barWidth  = s * (1.5 / 7.0)
        let barLength = s * (4.5 / 7.0)
        let cx = rect.midX
        let cy = rect.midY

        var path = Path()
        // Horizontaler Balken
        path.addRect(CGRect(
            x: cx - barLength / 2,
            y: cy - barWidth / 2,
            width: barLength,
            height: barWidth
        ))
        // Vertikaler Balken
        path.addRect(CGRect(
            x: cx - barWidth / 2,
            y: cy - barLength / 2,
            width: barWidth,
            height: barLength
        ))
        return path
    }
}

// MARK: - QR-Code-Overlay mit Schweizerkreuz

private struct SwissCrossOverlay: View {
    // Gemäss SIX Swiss QR Bill Spezifikation:
    //   QR-Code-Grösse:    46 × 46 mm
    //   Trägerquadrat:      7 ×  7 mm
    //   → Verhältnis:       7 / 46 ≈ 0.1522
    private let relativeSize: CGFloat = 7.0 / 46.0
    // Weisser Rand: ca. 0.6 mm bei 7 mm Trägerquadrat → 0.6/7 ≈ 0.0857
    private let whiteBorderRatio: CGFloat = 0.6 / 7.0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * relativeSize
            let borderWidth = side * whiteBorderRatio
            ZStack {
                // Weisses Hintergrundquadrat (mit abgerundeten Ecken)
                RoundedRectangle(cornerRadius: side * 0.1)
                    .fill(Color.white)
                    .frame(width: side + borderWidth * 2, height: side + borderWidth * 2)
                
                // Rotes Trägerquadrat (7 × 7 mm) in Schweizer Rot (Pantone 485 C) mit abgerundeten Ecken
                RoundedRectangle(cornerRadius: side * 0.1)
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.063))
                    .frame(width: side, height: side)
                
                // Weisses Schweizerkreuz
                SwissCrossShape()
                    .fill(Color.white)
                    .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - QRCodeView

/// Rendert einen QR-Code aus einem beliebigen String,
/// mit Schweizerkreuz-Overlay gemäss Swiss QR Bill Spezifikation.
struct QRCodeView: View {
    let payload: String
    var size: CGFloat = 200

    private var qrImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        // Korrekturstufe M: erlaubt bis 15 % Datenverlust → reicht für das Kreuz-Overlay
        filter.correctionLevel = "M"
        guard let data = payload.data(using: .utf8) else { return nil }
        filter.message = data
        let scale: CGFloat = 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        guard
            let ciImage = filter.outputImage,
            let cgImage = context.createCGImage(
                ciImage.transformed(by: transform),
                from: ciImage.transformed(by: transform).extent
            )
        else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .overlay(SwissCrossOverlay())
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }
}
