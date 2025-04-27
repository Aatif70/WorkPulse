import Foundation
import SwiftData

@MainActor
struct PreviewContainer {
    static let modelContext: ModelContext = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Session.self, configurations: config)
            let context = container.mainContext
            
            // Add some sample data for previews
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            
            // Yesterday's sessions
            let session1 = Session(
                startTime: yesterday.addingTimeInterval(-3600 * 5),
                endTime: yesterday.addingTimeInterval(-3600 * 2)
            )
            
            let session2 = Session(
                startTime: yesterday.addingTimeInterval(-3600),
                endTime: yesterday
            )
            
            // Today's sessions
            let session3 = Session(
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600)
            )
            
            let session4 = Session(
                startTime: Date().addingTimeInterval(-1800),
                endTime: Date().addingTimeInterval(-900)
            )
            
            // Manual entry
            let session5 = Session(
                startTime: Date().addingTimeInterval(-10800),
                endTime: Date().addingTimeInterval(-9000),
                isManualEntry: true
            )
            
            [session1, session2, session3, session4, session5].forEach {
                context.insert($0)
            }
            
            return context
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()
} 