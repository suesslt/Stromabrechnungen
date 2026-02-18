//
//  StromabrechnungenApp.swift
//  Stromabrechnungen
//

import SwiftUI
import SwiftData

@main
struct StromabrechnungenApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Stromgemeinschaft.self,
            Stromrechnung.self,
            Stromabrechnung.self,
            Bezugspartei.self,
            Parteienabrechnung.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
//            cloudKitDatabase: .private("iCloud.com.suessli.Stromabrechnungen") // suessli.Stromabrechnungen
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
