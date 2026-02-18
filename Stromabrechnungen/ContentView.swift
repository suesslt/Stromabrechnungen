//
//  ContentView.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stromgemeinschaft.bezeichnung) private var gemeinschaften: [Stromgemeinschaft]

    @State private var zeigeNeuAnlegen = false

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if gemeinschaften.isEmpty {
                    ContentUnavailableView(
                        "Keine Stromgemeinschaften",
                        systemImage: "bolt.circle",
                        description: Text("Tippe auf das +-Symbol, um eine neue Stromgemeinschaft anzulegen.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(gemeinschaften) { gemeinschaft in
                            NavigationLink(destination: StromgemeinschaftDetailView(gemeinschaft: gemeinschaft)) {
                                StromgemeinschaftKachel(gemeinschaft: gemeinschaft)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Stromgemeinschaften")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        zeigeNeuAnlegen = true
                    } label: {
                        Label("Neue Stromgemeinschaft", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $zeigeNeuAnlegen) {
                StromgemeinschaftBearbeitenView()
            }
        }
    }
}

// MARK: - Kachel

struct StromgemeinschaftKachel: View {
    let gemeinschaft: Stromgemeinschaft

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hintergrundbild oder Fallback
            Group {
                if let bildData = gemeinschaft.bild,
                   let uiImage = UIImage(data: bildData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(height: 160)
            .clipped()

            // Titel-Overlay
            VStack(alignment: .leading, spacing: 2) {
                Text(gemeinschaft.bezeichnung)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(gemeinschaft.abrechnungskonto)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Stromgemeinschaft.self,
            Stromrechnung.self,
            Stromabrechnung.self,
            Bezugspartei.self,
            Parteienabrechnung.self,
        ], inMemory: true)
}
