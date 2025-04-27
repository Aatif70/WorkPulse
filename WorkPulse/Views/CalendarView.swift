import SwiftUI
import UIKit

// MARK: - Calendar View
struct CalendarView: View {
    var viewModel: TimesheetViewModel
    @State private var selectedDate = Date()
    @State private var monthOffset = 0
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Start week on Monday
        return calendar
    }
    
    private var currentMonthDate: Date {
        let components = DateComponents(month: monthOffset)
        return calendar.date(byAdding: components, to: Date()) ?? Date()
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonthDate)
    }
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let startDate = monthFirstWeek.start
        let endDate = monthLastWeek.end
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate < endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.systemBackground).opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month header with enhanced styling
                    VStack(spacing: 4) {
                        HStack {
                            Button {
                                withAnimation {
                                    monthOffset -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.appAccent)
                                    .padding(12)
                                    .background(Circle().fill(Color(UIColor.secondarySystemBackground)))
                            }
                            
                            Spacer()
                            
                            Text(monthTitle)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundColor(.primary)
                                .animation(.none, value: monthOffset)
                                .transition(.opacity)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    monthOffset += 1
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.appAccent)
                                    .padding(12)
                                    .background(Circle().fill(Color(UIColor.secondarySystemBackground)))
                            }
                        }
                        
                        // Year switcher
                        if monthOffset != 0 {
                            Button {
                                withAnimation {
                                    monthOffset = 0
                                }
                            } label: {
                                Text("Return to Current Month")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(.appAccent)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.appAccent.opacity(0.1))
                                    )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Day headers
                    HStack(spacing: 0) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(days, id: \.self) { date in
                            CalendarDayView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonthDate, toGranularity: .month),
                                hasActivity: viewModel.hasActivityOn(date: date)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Selected day sessions - with enhanced card design
                    VStack(alignment: .leading, spacing: 0) {
                        // Selected date header
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedDateFormatted)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(sessionCountText)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    // Share button
                                    Button {
                                        showShareSheet = true
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.headline)
                                            .foregroundColor(.appAccent)
                                            .padding(12)
                                            .background(
                                                Circle()
                                                    .fill(Color.appAccent.opacity(0.1))
                                            )
                                    }
                                    
                                    // Add session button
                                    Button {
                                        // Functionality to add a session on this date
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.headline)
                                            .foregroundColor(.appAccent)
                                            .padding(12)
                                            .background(
                                                Circle()
                                                    .fill(Color.appAccent.opacity(0.1))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            
                            Divider()
                                .background(Color.secondary.opacity(0.2))
                        }
                        
                        // Sessions list or empty state
                        if viewModel.sessionsForDate(date: selectedDate).isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.bottom, 4)
                                
                                Text("No sessions recorded on this day")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    // Functionality to add a session on this date
                                } label: {
                                    Text("Add Session")
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.appAccent)
                                        .clipShape(Capsule())
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.sessionsForDate(date: selectedDate), id: \.startTime) { session in
                                        CalendarSessionRow(session: session)
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [generateShareText()])
            }
        }
    }
    
    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var sessionCountText: String {
        let sessions = viewModel.sessionsForDate(date: selectedDate)
        return sessions.count == 1 ? "1 session" : "\(sessions.count) sessions"
    }
    
    private func generateShareText() -> String {
        let sessions = viewModel.sessionsForDate(date: selectedDate)
        
        var text = "WorkPulse Summary - \(selectedDateFormatted)\n\n"
        
        if sessions.isEmpty {
            text += "No work sessions recorded on this day."
        } else {
            text += "Work Sessions (\(sessions.count)):\n"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            
            // Calculate total duration
            let totalDuration = sessions.compactMap { $0.duration }.reduce(0, +)
            let hours = Int(totalDuration) / 3600
            let minutes = Int(totalDuration) / 60 % 60
            
            text += "Total Work Time: \(hours)h \(minutes)m\n\n"
            
            for (index, session) in sessions.enumerated() {
                let startTime = formatter.string(from: session.startTime)
                let endTimeString = session.endTime != nil ? formatter.string(from: session.endTime!) : "Ongoing"
                text += "Session \(index + 1): \(startTime) - \(endTimeString)\n"
                text += "Duration: \(session.formattedDuration)\n"
                if session.isManualEntry {
                    text += "(Manually added)\n"
                }
                text += "\n"
            }
        }
        
        text += "Shared via WorkPulse Timesheet App"
        
        return text
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    var date: Date
    var isSelected: Bool
    var isToday: Bool
    var isCurrentMonth: Bool
    var hasActivity: Bool
    
    var calendar = Calendar.current
    
    var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                )
            
            VStack(spacing: 3) {
                Text(dayNumber)
                    .font(.system(isToday ? .body : .callout, design: .rounded, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Activity indicator - small horizontal bar instead of a dot
                if hasActivity {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isSelected ? Color.white : Color.appAccent)
                        .frame(width: 16, height: 2)
                }
            }
        }
        .frame(height: 40)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
    
    var backgroundColor: Color {
        if isSelected {
            return Color.appAccent
        } else if isToday {
            return Color.appAccent.opacity(0.15)
        } else {
            return Color(UIColor.secondarySystemBackground)
        }
    }
    
    var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .appAccent
        } else {
            return .primary
        }
    }
}

// MARK: - Calendar Session Row
struct CalendarSessionRow: View {
    var session: Session
    
    var body: some View {
        HStack(spacing: 16) {
            // Time column
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.startTime, style: .time)
                        .font(.system(.body, design: .rounded, weight: .medium))
                }
                
                if let endTime = session.endTime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(endTime, style: .time)
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Duration pill with gradient
            Text(session.formattedDuration)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    session.duration ?? 0 > 3600 ? Color.appSuccess : Color.appAccent,
                                    session.duration ?? 0 > 3600 ? Color.appSuccess.opacity(0.8) : Color.appSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            
            Spacer()
            
            if session.isManualEntry {
                VStack(alignment: .center, spacing: 2) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.appWarning)
                    
                    Text("Manual")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appWarning.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        )
    }
} 