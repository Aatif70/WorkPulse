import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable
class TimesheetViewModel {
    // Timer properties
    private var timer: Timer?
    var currentTime: TimeInterval = 0
    var isRunning: Bool = false
    var sessionStartTime: Date?
    
    // Day status
    var isDayEnded: Bool = false
    private let dayEndedKey = "WorkPulse.isDayEnded"
    
    // Session properties
    private var modelContext: ModelContext
    var todaySessions: [Session] = []
    var allSessions: [Session] = []
    
    // Computed properties
    var todayTotalTime: TimeInterval {
        let total = todaySessions.compactMap { $0.duration }.reduce(0, +)
        return isRunning ? total + currentTime : total
    }
    
    var formattedCurrentTime: String {
        return currentTime.formatAsHoursMinutesSeconds()
    }
    
    var formattedTodayTotalTime: String {
        return todayTotalTime.formatAsHoursMinutesSeconds()
    }
    
    // Initialize with model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load day ended status from UserDefaults
        isDayEnded = UserDefaults.standard.bool(forKey: dayEndedKey)
        
        // Check if day has changed since last run
        checkAndResetDayStatus()
        
        loadSessions()
    }
    
    // MARK: - Day Status Management
    
    private func checkAndResetDayStatus() {
        // Get the last recorded day
        let lastDateKey = "WorkPulse.lastRecordedDate"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDateString = UserDefaults.standard.string(forKey: lastDateKey),
           let lastDate = ISO8601DateFormatter().date(from: lastDateString) {
            
            // If the recorded date is not today, reset day status
            let lastDay = calendar.startOfDay(for: lastDate)
            if !calendar.isDate(lastDay, inSameDayAs: today) {
                isDayEnded = false
                UserDefaults.standard.set(false, forKey: dayEndedKey)
            }
        }
        
        // Update the last recorded date
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: today), forKey: lastDateKey)
    }
    
    func endDay() {
        // Stop the timer if it's running
        if isRunning {
            stopTimer()
        }
        
        // Mark the day as ended
        isDayEnded = true
        UserDefaults.standard.set(true, forKey: dayEndedKey)
    }
    
    func resumeDay() {
        // Mark the day as not ended
        isDayEnded = false
        UserDefaults.standard.set(false, forKey: dayEndedKey)
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        // Check if day is ended
        if isDayEnded { return }
        
        if isRunning { return }
        
        isRunning = true
        sessionStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime += 1.0
        }
    }
    
    func stopTimer() {
        guard isRunning, let startTime = sessionStartTime else { return }
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        let endTime = Date()
        let newSession = Session(startTime: startTime, endTime: endTime)
        saveSession(newSession)
        
        // Reset timer
        currentTime = 0
        sessionStartTime = nil
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: Session) {
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            loadSessions() // Refresh sessions
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func deleteSession(_ session: Session) {
        modelContext.delete(session)
        
        do {
            try modelContext.save()
            loadSessions() // Refresh sessions
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    func updateSession(_ session: Session) {
        if let endTime = session.endTime {
            session.duration = endTime.timeIntervalSince(session.startTime)
        }
        
        do {
            try modelContext.save()
            loadSessions() // Refresh sessions
        } catch {
            print("Failed to update session: \(error)")
        }
    }
    
    func addManualSession(startTime: Date, endTime: Date) {
        let newSession = Session(startTime: startTime, endTime: endTime, isManualEntry: true)
        saveSession(newSession)
    }
    
    // MARK: - Data Loading
    
    func loadSessions() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let todayPredicate = #Predicate<Session> { 
            $0.startTime >= startOfDay && $0.startTime < endOfDay
        }
        
        do {
            let descriptor = FetchDescriptor<Session>(
                predicate: todayPredicate,
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            todaySessions = try modelContext.fetch(descriptor)
            
            let allDescriptor = FetchDescriptor<Session>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            allSessions = try modelContext.fetch(allDescriptor)
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    func groupedSessions() -> [Date: [Session]] {
        let calendar = Calendar.current
        var grouped = [Date: [Session]]()
        
        for session in allSessions {
            let startOfDay = calendar.startOfDay(for: session.startTime)
            if grouped[startOfDay] == nil {
                grouped[startOfDay] = [session]
            } else {
                grouped[startOfDay]?.append(session)
            }
        }
        
        return grouped
    }
    
    // MARK: - Calendar & Date Functions
    
    func hasActivityOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return allSessions.contains { session in
            session.startTime >= dayStart && session.startTime < dayEnd
        }
    }
    
    func sessionsForDate(date: Date) -> [Session] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let sessions = allSessions.filter { session in
            session.startTime >= dayStart && session.startTime < dayEnd
        }
        
        return sessions.sorted { $0.startTime > $1.startTime }
    }
    
    func totalTimeForDate(date: Date) -> TimeInterval {
        let sessions = sessionsForDate(date: date)
        let totalTime = sessions.compactMap { $0.duration }.reduce(0, +)
        
        return totalTime
    }
    
    func formattedTotalTimeForDate(date: Date) -> String {
        return totalTimeForDate(date: date).formatAsHoursMinutesSeconds()
    }
    
    func exportDataForMonth(month: Date, format: String = "csv") -> Data? {
        // Implementation will be added later
        return nil
    }
} 