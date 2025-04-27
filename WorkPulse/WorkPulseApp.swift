//
//  WorkPulseApp.swift
//  WorkPulse
//
//  Created by Aatif Ahmed on 4/27/25.
//

import SwiftUI
import SwiftData

@main
struct WorkPulseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
