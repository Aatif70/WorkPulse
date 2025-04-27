import Foundation
import SwiftData

@Model
class Session {
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var isManualEntry: Bool
    
    init(startTime: Date = Date(), endTime: Date? = nil, isManualEntry: Bool = false) {
        self.startTime = startTime
        self.endTime = endTime
        self.isManualEntry = isManualEntry
        
        if let endTime = endTime {
            self.duration = endTime.timeIntervalSince(startTime)
        }
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "00:00:00" }
        return duration.formatAsHoursMinutesSeconds()
    }
}

// Extension to format TimeInterval as HH:MM:SS
extension TimeInterval {
    func formatAsHoursMinutesSeconds() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
} 