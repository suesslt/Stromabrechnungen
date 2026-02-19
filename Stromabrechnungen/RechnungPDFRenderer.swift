//
//  RechnungPDFRenderer.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import UIKit
import CoreImage.CIFilterBuiltins
import CoreGraphics

// MARK: - Masse (Punkte bei 72 dpi)
// 1 mm = 72/25.4 pt ≈ 2.8346 pt

private enum PDFMass {
    static let ptPerMm: CGFloat       = 72.0 / 25.4

    // A4
    static let pageWidth: CGFloat     = 210 * ptPerMm   // 595.28 pt
    static let pageHeight: CGFloat    = 297 * ptPerMm   // 841.89 pt

    // Ränder
    static let marginLeft: CGFloat    = 20  * ptPerMm
    static let marginRight: CGFloat   = 20  * ptPerMm
    static let marginTop: CGFloat     = 20  * ptPerMm

    // Zahlteil (SIX Swiss QR Bill Spezifikation)
    static let zahlteilHeight: CGFloat = 105 * ptPerMm  // 297.64 pt
    static let qrCodeSize: CGFloat     =  46 * ptPerMm  // 130.39 pt  ← exakt 46 mm
    static let qrLeft: CGFloat         =   5 * ptPerMm
    static let qrTop: CGFloat          =  17 * ptPerMm  // Abstand vom Zahlteil-Oberkant

    // Schriften
    static let fontTitle: CGFloat      = 14
    static let fontHeading: CGFloat    = 8
    static let fontBody: CGFloat       = 10
    static let fontSmall: CGFloat      = 8
}

// MARK: - Renderer

struct RechnungPDFRenderer {

    let rechnung: Parteienrechnung
    let kreditor: QRAddress
    let bill: QRBill

    private static let chfFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CHF"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private var rechnungstitel: String {
        let von = rechnung.rechnungszeitraumVon.formatted(date: .abbreviated, time: .omitted)
        let bis = rechnung.rechnungszeitraumBis.formatted(date: .abbreviated, time: .omitted)
        return "Stromabrechnung \(von) – \(bis)"
    }

    // MARK: - Öffentliche API

    /// Rendert das Rechnungs-PDF und gibt die Daten zurück.
    func render() -> Data {
        let pageRect = CGRect(
            x: 0, y: 0,
            width: PDFMass.pageWidth,
            height: PDFMass.pageHeight
        )
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let cgCtx = ctx.cgContext
            drawRechnungskopf(in: cgCtx, pageRect: pageRect)
            drawAdressen(in: cgCtx, pageRect: pageRect)
            drawRechnungsdetails(in: cgCtx, pageRect: pageRect)
            drawZahlteil(in: cgCtx, pageRect: pageRect)
        }
    }

    // MARK: - Rechnungskopf

    private func drawRechnungskopf(in ctx: CGContext, pageRect: CGRect) {
        let x = PDFMass.marginLeft
        var y = PDFMass.marginTop

        // Titel
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontTitle, weight: .bold)
        ]
        "Stromrechnung".draw(at: CGPoint(x: x, y: y), withAttributes: titleAttr)
        y += PDFMass.fontTitle + 4

        // Zeitraum
        let subAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontBody),
            .foregroundColor: UIColor.secondaryLabel
        ]
        rechnungstitel.draw(at: CGPoint(x: x, y: y), withAttributes: subAttr)
        y += PDFMass.fontBody + 4

        // Trennlinie
        drawHRule(in: ctx, y: y + 6, pageRect: pageRect)
    }

    // MARK: - Adressen

    private func drawAdressen(in ctx: CGContext, pageRect: CGRect) {
        let topY = PDFMass.marginTop + PDFMass.fontTitle + 4 + PDFMass.fontBody + 4 + 20
        let contentWidth = pageRect.width - PDFMass.marginLeft - PDFMass.marginRight
        let colWidth = contentWidth / 2

        // ── Kreditor (links) ──────────────────────────────────────────────────
        var y = topY
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontHeading, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let boldAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontBody, weight: .semibold)
        ]
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontBody)
        ]

        "Von".draw(at: CGPoint(x: PDFMass.marginLeft, y: y), withAttributes: labelAttr)
        y += PDFMass.fontHeading + 3
        kreditor.name.draw(at: CGPoint(x: PDFMass.marginLeft, y: y), withAttributes: boldAttr)
        y += PDFMass.fontBody + 2
        "\(kreditor.street) \(kreditor.houseNumber)".draw(at: CGPoint(x: PDFMass.marginLeft, y: y), withAttributes: bodyAttr)
        y += PDFMass.fontBody + 2
        "\(kreditor.postalCode) \(kreditor.city)".draw(at: CGPoint(x: PDFMass.marginLeft, y: y), withAttributes: bodyAttr)
        y += PDFMass.fontBody + 2
        kreditor.countryCode.draw(at: CGPoint(x: PDFMass.marginLeft, y: y), withAttributes: bodyAttr)

        // ── Debtor (rechts, rechtsbündig) ─────────────────────────────────────
        if let partei = rechnung.bezugspartei {
            var ry = topY
            let rightEdge = pageRect.width - PDFMass.marginRight
            let lines: [(String, [NSAttributedString.Key: Any])] = [
                ("An",                                  labelAttr),
                (partei.name,                           boldAttr),
                ("\(partei.street) \(partei.houseNumber)", bodyAttr),
                ("\(partei.postalCode) \(partei.city)", bodyAttr),
                (partei.countryCode,                    bodyAttr)
            ]
            for (line, attr) in lines {
                let w = (line as NSString).size(withAttributes: attr).width
                (line as NSString).draw(
                    at: CGPoint(x: rightEdge - w, y: ry),
                    withAttributes: attr
                )
                let fontSize = (attr[.font] as? UIFont)?.pointSize ?? PDFMass.fontBody
                ry += fontSize + (line == "An" ? 3 : 2)
            }
        }

        // Trennlinie unter Adressen
        let hRuleY = topY + (PDFMass.fontHeading + 3) + 4 * (PDFMass.fontBody + 2) + 10
        drawHRule(in: ctx, y: hRuleY, pageRect: pageRect)
    }

    // MARK: - Rechnungsdetails

    private func drawRechnungsdetails(in ctx: CGContext, pageRect: CGRect) {
        let topY = PDFMass.marginTop
            + PDFMass.fontTitle + 4
            + PDFMass.fontBody  + 4
            + 20                         // nach Kopf-HRule
            + (PDFMass.fontHeading + 3)
            + 4 * (PDFMass.fontBody + 2)
            + 20                         // nach Adress-HRule

        var y = topY
        let x = PDFMass.marginLeft
        let rightEdge = pageRect.width - PDFMass.marginRight

        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontBody),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: PDFMass.fontBody, weight: .regular)
        ]
        let valueBoldAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: PDFMass.fontBody, weight: .bold)
        ]

        let rows: [(String, String, [NSAttributedString.Key: Any])] = [
            ("Rechnungsdatum",
             rechnung.rechnungsdatum.formatted(date: .abbreviated, time: .omitted),
             valueAttr),
            ("Bezugsmenge",
             "\(rechnung.abgerechneteBezugsmenge.formatted()) kWh",
             valueAttr),
            ("Rechnungsbetrag",
             Self.chfFormatter.string(from: rechnung.abgerechneterBetrag as NSDecimalNumber) ?? "",
             valueBoldAttr),
        ]

        for (label, value, valAttr) in rows {
            (label as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: labelAttr)
            let w = (value as NSString).size(withAttributes: valAttr).width
            (value as NSString).draw(at: CGPoint(x: rightEdge - w, y: y), withAttributes: valAttr)
            y += PDFMass.fontBody + 6
        }

        if let gemeinschaft = rechnung.bezugspartei?.stromgemeinschaft {
            let label = "IBAN"
            let value = gemeinschaft.abrechnungskonto
            (label as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: labelAttr)
            let w = (value as NSString).size(withAttributes: valueAttr).width
            (value as NSString).draw(at: CGPoint(x: rightEdge - w, y: y), withAttributes: valueAttr)
            y += PDFMass.fontBody + 6
        }
    }

    // MARK: - Zahlteil (SIX Swiss QR Bill)

    private func drawZahlteil(in ctx: CGContext, pageRect: CGRect) {
        let zahlteilY = pageRect.height - PDFMass.zahlteilHeight

        // Trennlinie oben mit Scheren-Symbol
        drawZahlteilTrennlinie(in: ctx, y: zahlteilY, pageRect: pageRect)

        // "ZAHLTEIL" Überschrift (links) + "EMPFANGSSCHEIN" (rechts)
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]

        // Linke Spalte: QR-Code + Währung/Betrag
        let leftColX = PDFMass.qrLeft
        var y = zahlteilY + 10

        "ZAHLTEIL".draw(at: CGPoint(x: leftColX, y: y), withAttributes: titleAttr)
        y += 16

        // QR-Code als Bitmap rendern (exakt 46 mm)
        if let qrImage = renderQRCodeImage(size: PDFMass.qrCodeSize) {
            let qrRect = CGRect(
                x: leftColX,
                y: y,
                width: PDFMass.qrCodeSize,
                height: PDFMass.qrCodeSize
            )
            // Koordinatensystem in PDF ist von oben nach unten → kein Flip nötig bei UIImage.draw
            ctx.saveGState()
            // UIKit-Koordinaten: flip für CoreGraphics
            ctx.translateBy(x: 0, y: pageRect.height)
            ctx.scaleBy(x: 1, y: -1)
            let flippedRect = CGRect(
                x: qrRect.minX,
                y: pageRect.height - qrRect.maxY,
                width: qrRect.width,
                height: qrRect.height
            )
            ctx.draw(qrImage.cgImage!, in: flippedRect)
            ctx.restoreGState()
            y += PDFMass.qrCodeSize + 8
        }

        // Währung & Betrag unter dem QR-Code
        let headingAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontHeading, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let monoAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: PDFMass.fontBody, weight: .bold)
        ]
        let monoSmallAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: PDFMass.fontBody, weight: .regular)
        ]

        "Währung".draw(at: CGPoint(x: leftColX, y: y), withAttributes: headingAttr)
        "Betrag".draw(at: CGPoint(x: leftColX + 30 * PDFMass.ptPerMm, y: y), withAttributes: headingAttr)
        y += PDFMass.fontHeading + 3
        bill.currency.draw(at: CGPoint(x: leftColX, y: y), withAttributes: monoSmallAttr)
        let betragStr = Self.chfFormatter.string(from: rechnung.abgerechneterBetrag as NSDecimalNumber) ?? ""
        betragStr.draw(at: CGPoint(x: leftColX + 30 * PDFMass.ptPerMm, y: y), withAttributes: monoAttr)

        // Rechte Spalte: Zahlungsinfos (Konto/Zahlbar an / Zahlbar durch)
        let rightColX = PDFMass.qrLeft + PDFMass.qrCodeSize + 8 * PDFMass.ptPerMm
        var ry = zahlteilY + 10 + 16 // gleicher Startpunkt wie QR-Code

        let smallLabelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontSmall, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let smallBoldAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontSmall + 1, weight: .semibold)
        ]
        let smallBodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PDFMass.fontSmall + 1)
        ]

        // Konto/Zahlbar an
        "Konto / Zahlbar an".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallLabelAttr)
        ry += PDFMass.fontSmall + 3
        bill.iban.draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
        ry += PDFMass.fontSmall + 2 + 2
        kreditor.name.draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBoldAttr)
        ry += PDFMass.fontSmall + 2 + 2
        "\(kreditor.street) \(kreditor.houseNumber)".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
        ry += PDFMass.fontSmall + 2 + 2
        "\(kreditor.postalCode) \(kreditor.city)".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
        ry += PDFMass.fontSmall + 2 + 8

        // Zusatzinformationen (Rechnungstitel)
        "Zusätzliche Informationen".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallLabelAttr)
        ry += PDFMass.fontSmall + 3
        rechnungstitel.draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
        ry += PDFMass.fontSmall + 2 + 8

        // Zahlbar durch
        if let partei = rechnung.bezugspartei {
            "Zahlbar durch".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallLabelAttr)
            ry += PDFMass.fontSmall + 3
            partei.name.draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBoldAttr)
            ry += PDFMass.fontSmall + 2 + 2
            "\(partei.street) \(partei.houseNumber)".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
            ry += PDFMass.fontSmall + 2 + 2
            "\(partei.postalCode) \(partei.city)".draw(at: CGPoint(x: rightColX, y: ry), withAttributes: smallBodyAttr)
        }
    }

    // MARK: - QR-Code Bitmap rendern (exakt 46 mm bei 72 dpi = 130.39 pt)

    private func renderQRCodeImage(size: CGFloat) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "M"
        guard let data = bill.generatePayload().data(using: .utf8) else { return nil }
        filter.message = data
        guard let ciImage = filter.outputImage else { return nil }

        // Skaliere den rohen QR-Code auf die gewünschte Punktgrösse
        let ciExtent = ciImage.extent
        let scaleX = size / ciExtent.width
        let scaleY = size / ciExtent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        // Schweizerkreuz einzeichnen
        let qrSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: qrSize)
        return renderer.image { _ in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: qrSize))
            drawSwissCross(in: CGRect(origin: .zero, size: qrSize))
        }
    }

    /// Zeichnet das Schweizerkreuz (rotes Quadrat + weisses Kreuz) gemäss SIX-Spezifikation.
    private func drawSwissCross(in rect: CGRect) {
        let qr = min(rect.width, rect.height)

        // Trägerquadrat: 7 mm bei 46 mm QR-Code
        let squareSide = qr * (7.0 / 46.0)
        let squareX = rect.midX - squareSide / 2
        let squareY = rect.midY - squareSide / 2
        let squareRect = CGRect(x: squareX, y: squareY, width: squareSide, height: squareSide)

        // Rot (Pantone 485 C)
        UIColor(red: 1.0, green: 0.0, blue: 0.063, alpha: 1.0).setFill()
        UIRectFill(squareRect)

        // Kreuzbalken: 1.5 mm breit, 4.5 mm lang (relativ zum 7 mm Quadrat)
        let barWidth  = squareSide * (1.5 / 7.0)
        let barLength = squareSide * (4.5 / 7.0)
        UIColor.white.setFill()
        // Horizontaler Balken
        UIRectFill(CGRect(
            x: rect.midX - barLength / 2,
            y: rect.midY - barWidth  / 2,
            width: barLength, height: barWidth
        ))
        // Vertikaler Balken
        UIRectFill(CGRect(
            x: rect.midX - barWidth  / 2,
            y: rect.midY - barLength / 2,
            width: barWidth, height: barLength
        ))
    }

    // MARK: - Hilfszeichnungen

    private func drawHRule(in ctx: CGContext, y: CGFloat, pageRect: CGRect) {
        ctx.saveGState()
        ctx.setStrokeColor(UIColor.separator.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: PDFMass.marginLeft, y: y))
        ctx.addLine(to: CGPoint(x: pageRect.width - PDFMass.marginRight, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawZahlteilTrennlinie(in ctx: CGContext, y: CGFloat, pageRect: CGRect) {
        ctx.saveGState()
        // Gestrichelte Linie
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(0.5)
        ctx.setLineDash(phase: 0, lengths: [3, 3])
        ctx.move(to: CGPoint(x: 0, y: y))
        ctx.addLine(to: CGPoint(x: pageRect.width, y: y))
        ctx.strokePath()
        ctx.restoreGState()

        // Scheren-Symbol zentriert
        let scissorsAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10)
        ]
        let scissorsStr = "✂"
        let size = (scissorsStr as NSString).size(withAttributes: scissorsAttr)
        (scissorsStr as NSString).draw(
            at: CGPoint(x: pageRect.width / 2 - size.width / 2, y: y - size.height / 2),
            withAttributes: scissorsAttr
        )
    }
}
