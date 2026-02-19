//
//  QRCodeView.swift
//  Stromabrechnungen
//
//  Created by Thomas Süssli on 19.02.2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Rendert einen QR-Code aus einem beliebigen String.
struct QRCodeView: View {
    let payload: String
    var size: CGFloat = 200

    private var qrImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "M"
        guard let data = payload.data(using: .utf8) else { return nil }
        filter.message = data
        guard
            let ciImage = filter.outputImage,
            let cgImage = context.createCGImage(
                ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
                from: ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)).extent
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
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }
}
