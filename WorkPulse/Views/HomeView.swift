import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    var viewModel: TimesheetViewModel?
    @State private var localViewModel: TimesheetViewModel?
    @State private var showingManualEntrySheet = false
    @State private var showingQuickSessionsList = true
    @State private var showingCalendarView = false
    @State private var showingEndDaySheet = false
    
    // Toast
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSuccessToast = true
    
    // Animations
    @State private var timerAppears = false
    @State private var summaryAppears = false
    @State private var buttonAppears = false
    @State private var timerScale: CGFloat = 1.0
    @State private var timerPulse = false
    
    var body: some View {
        NavigationStack {
            mainContentView
                .navigationTitle("WorkPulse")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("WorkPulse")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.appAccent, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if let vm = activeViewModel {
                                NavigationLink(destination: SessionHistoryView(viewModel: vm)) {
                                    Label("History", systemImage: "clock.arrow.circlepath")
                                }
                            }
                            
                            Button {
                                showingCalendarView = true
                            } label: {
                                Label("Calendar", systemImage: "calendar")
                            }
                            
                            Button {
                                showingEndDaySheet = true
                            } label: {
                                Label("End Day", systemImage: "moon.stars")
                            }
                            
                            Divider()
                            
                            Button {
                                // Export feature will be implemented later
                                toastMessage = "Export feature coming soon!"
                                isSuccessToast = true
                                showToast = true
                            } label: {
                                Label("Export Month", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(.headline))
                                .foregroundColor(.appAccent)
                        }
                    }
                }
                .onChange(of: activeViewModel?.isRunning) { oldValue, newValue in
                    if let oldVal = oldValue, let newVal = newValue {
                        if !oldVal && newVal {
                            // Timer started - play start animation
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                // Animation logic if needed
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingManualEntrySheet) {
                    if let vm = activeViewModel {
                        ManualSessionForm(
                            onSave: { startTime, endTime in
                                vm.addManualSession(startTime: startTime, endTime: endTime)
                                showingManualEntrySheet = false
                                
                                // Show success message
                                toastMessage = "Manual session added successfully! ✅"
                                isSuccessToast = true
                                showToast = true
                            },
                            onCancel: {
                                showingManualEntrySheet = false
                            }
                        )
                    }
                }
                .sheet(isPresented: $showingCalendarView) {
                    if let vm = activeViewModel {
                        CalendarView(viewModel: vm)
                    }
                }
                .sheet(isPresented: $showingEndDaySheet) {
                    if let vm = activeViewModel {
                        EndDayView(viewModel: vm, isPresented: $showingEndDaySheet)
                    }
                }
                .onAppear {
                    // Initialize the view model if needed
                    if activeViewModel == nil {
                        localViewModel = TimesheetViewModel(modelContext: modelContext)
                    }
                    
                    // Staggered appearance animations
                    withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                        summaryAppears = true
                    }
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                        timerAppears = true
                    }
                    
                    withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                        buttonAppears = true
                    }
                    
                    // Initialize timer pulse if needed
                    timerPulse = activeViewModel?.isRunning ?? false
                }
                .toast(isShowing: $showToast, message: toastMessage, isSuccess: isSuccessToast)
        }
    }
    
    // MARK: - Content Views
    
    private var mainContentView: some View {
        ZStack {
            // Background with enhanced gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Animated background shapes
            ZStack {
                // Background decorative shapes
                Circle()
                    .fill(LinearGradient(
                        colors: [.appAccent.opacity(0.3), .appSecondary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(LinearGradient(
                        colors: [.appSecondary.opacity(0.2), .appSuccess.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 150, y: 300)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Today's Summary Card
                    SummaryCardView
                    
                    // Timer Display
                    TimerCardView
                    
                    // Quick Sessions List
                    RecentSessionsView
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            
            // Timer Button (Floating)
            FloatingTimerButton
        }
    }
    
    private var SummaryCardView: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Work")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(activeViewModel?.formattedTodayTotalTime ?? "00:00:00")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: circularProgressValue,
                    size: 75
                )
            }
            
            Divider()
                .background(Color.secondary.opacity(0.2))
                .padding(.vertical, 5)
            
            HStack(spacing: 0) {
                InfoBadge(
                    value: "\(activeViewModel?.todaySessions.count ?? 0)",
                    label: "Sessions",
                    systemImage: "list.bullet.clipboard"
                )
                
                Divider()
                    .frame(height: 30)
                    .background(Color.secondary.opacity(0.2))
                
                if let avgSession = calculateAverageSessionTime() {
                    InfoBadge(
                        value: avgSession,
                        label: "Average",
                        systemImage: "clock.arrow.2.circlepath"
                    )
                } else {
                    InfoBadge(
                        value: "--:--",
                        label: "Average",
                        systemImage: "clock.arrow.2.circlepath"
                    )
                }
                
                Divider()
                    .frame(height: 30)
                    .background(Color.secondary.opacity(0.2))
                
                InfoBadge(
                    value: formattedLastBreak(),
                    label: "Last Break",
                    systemImage: "cup.and.saucer"
                )
            }
        }
        .padding(20)
        .background(
            GlassmorphicCard()
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .opacity(summaryAppears ? 1 : 0)
        .offset(y: summaryAppears ? 0 : -20)
    }
    
    private var TimerCardView: some View {
        VStack(spacing: 15) {
            // Timer status indicator
            HStack {
                Text(activeViewModel?.isRunning ?? false ? "Timer Running" : "Timer Ready")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(activeViewModel?.isRunning ?? false ? .appSuccess : .secondary)
                
                Spacer()
                
                if activeViewModel?.isRunning ?? false {
                    RecordingIndicator
                }
            }
            
            // Timer digits with enhanced style
            Group {
                if activeViewModel?.isRunning ?? false {
                    Text(activeViewModel?.formattedCurrentTime ?? "00:00:00")
                        .font(.system(size: 65, weight: .semibold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.appAccent, .appSecondary], startPoint: .leading, endPoint: .trailing))
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .scaleEffect(timerScale)
                } else {
                    Text(activeViewModel?.formattedCurrentTime ?? "00:00:00")
                        .font(.system(size: 65, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .scaleEffect(timerScale)
                }
            }
            .animation(
                activeViewModel?.isRunning ?? false 
                ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                : .default,
                value: timerScale
            )
            
            // Session start time (if running)
            SessionStartTimeInfo
        }
        .padding(20)
        .background(
            GlassmorphicCard()
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .opacity(timerAppears ? 1 : 0)
        .scaleEffect(timerAppears ? 1 : 0.9)
    }
    
    private var RecordingIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.appSuccess)
                .frame(width: 8, height: 8)
                .opacity(timerPulse ? 0.5 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                    value: timerPulse
                )
                
            Text("Recording")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.appSuccess)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.appSuccess.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appSuccess.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var SessionStartTimeInfo: some View {
        Group {
            if activeViewModel?.isRunning ?? false, let startTime = activeViewModel?.sessionStartTime {
                HStack {
                    Text("Started at:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Duration: \(startTime, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemBackground)))
            }
        }
    }
    
    private var RecentSessionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(.system(.headline, design: .rounded))
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showingQuickSessionsList.toggle()
                    }
                } label: {
                    Label(
                        showingQuickSessionsList ? "Hide" : "Show",
                        systemImage: showingQuickSessionsList ? "chevron.up" : "chevron.down"
                    )
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if showingQuickSessionsList {
                SessionListContent
            }
        }
        .padding(20)
        .background(
            GlassmorphicCard()
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .padding(.horizontal)
        .opacity(summaryAppears ? 1 : 0)
    }
    
    private var SessionListContent: some View {
        VStack(spacing: 12) {
            ForEach(activeViewModel?.todaySessions.prefix(3) ?? [], id: \.startTime) { session in
                SessionRowView(session: session)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            
            if let vm = activeViewModel, vm.todaySessions.isEmpty {
                Text("No sessions recorded today")
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    )
            }
            
            if let vm = activeViewModel, vm.todaySessions.count > 3 {
                NavigationLink(destination: SessionHistoryView(viewModel: vm)) {
                    Text("View All \(vm.todaySessions.count) Sessions")
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .foregroundColor(.appAccent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.appAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
    
    private func SessionRowView(session: Session) -> some View {
        HStack(spacing: 14) {
            // Time indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.appAccent.opacity(0.7))
                    
                    Text(session.startTime, style: .time)
                        .font(.system(.callout, design: .rounded, weight: .medium))
                }
                
                if let endTime = session.endTime {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(endTime, style: .time)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Duration pill
            Text(session.formattedDuration)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(sessionColor(for: session))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(sessionColor(for: session).opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(sessionColor(for: session).opacity(0.3), lineWidth: 1)
                        )
                )
            
            Spacer()
            
            // Badges for session type (if any)
            if session.isManualEntry {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.appWarning.opacity(0.8))
                    .padding(4)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private var FloatingTimerButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Main timer control button
                    Button {
                        if activeViewModel?.isRunning ?? false {
                            activeViewModel?.stopTimer()
                            
                            // Show success message
                            toastMessage = EncouragingMessages.randomStopMessage()
                            isSuccessToast = true
                            showToast = true
                        } else {
                            activeViewModel?.startTimer()
                            
                            // Show start message
                            toastMessage = EncouragingMessages.randomStartMessage()
                            isSuccessToast = false
                            showToast = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(activeViewModel?.isRunning ?? false 
                                     ? Color.appSuccess.opacity(0.15) 
                                     : Color.appAccent.opacity(0.15))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            activeViewModel?.isRunning ?? false 
                                                ? Color.appSuccess 
                                                : Color.appAccent,
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: (activeViewModel?.isRunning ?? false 
                                              ? Color.appSuccess : Color.appAccent).opacity(0.3), 
                                      radius: 8, x: 0, y: 4)
                            
                            Image(systemName: activeViewModel?.isRunning ?? false 
                                  ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(activeViewModel?.isRunning ?? false 
                                               ? .appSuccess : .appAccent)
                        }
                    }
                    
                    // Secondary manual entry button
                    Button {
                        showingManualEntrySheet = true
                    } label: {
                        Text("Add Session")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.primary.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                .padding(.trailing, 25)
                .padding(.bottom, 25)
                .opacity(buttonAppears ? 1 : 0)
                .offset(y: buttonAppears ? 0 : 20)
            }
        }
    }
    
    // Background gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.systemBackground).opacity(0.95)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Helper Properties and Methods
    
    // Helper computed property to get the active view model (either passed in or local)
    private var activeViewModel: TimesheetViewModel? {
        viewModel ?? localViewModel
    }
    
    // Circular progress value
    private var circularProgressValue: Double {
        guard let todayTotalTime = activeViewModel?.todayTotalTime else { return 0.0 }
        return min(Double(todayTotalTime) / (8 * 3600), 1.0)
    }
    
    // Calculate average session time from today's sessions
    private func calculateAverageSessionTime() -> String? {
        guard let sessions = activeViewModel?.todaySessions, !sessions.isEmpty else {
            return nil
        }
        
        let durations = sessions.compactMap { $0.duration }
        guard !durations.isEmpty else { return nil }
        
        let totalTime = durations.reduce(0, +)
        let averageTime = totalTime / Double(durations.count)
        
        // Format as hours & minutes for average
        let hours = Int(averageTime) / 3600
        let minutes = Int(averageTime) / 60 % 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
    
    // Calculate time since last break (time between sessions)
    private func formattedLastBreak() -> String {
        guard let sessions = activeViewModel?.todaySessions, sessions.count >= 2 else {
            return "--:--"
        }
        
        // Sort sessions by start time (newest first)
        let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }
        
        // Get the two most recent completed sessions
        guard sortedSessions.count >= 2,
              let first = sortedSessions.first,
              sortedSessions.indices.contains(1),
              let _ = first.endTime,  // We only need to check if it exists
              let secondEndTime = sortedSessions[1].endTime else {
            return "--:--"
        }
        
        // Calculate the break time between end of previous session and start of latest session
        let breakTime = first.startTime.timeIntervalSince(secondEndTime)
        
        // Format as minutes if less than hour, otherwise as H:MM
        if breakTime < 3600 {
            let minutes = Int(breakTime) / 60
            return "\(minutes)m"
        } else {
            let hours = Int(breakTime) / 3600
            let minutes = Int(breakTime) / 60 % 60
            return String(format: "%d:%02d", hours, minutes)
        }
    }
    
    // Helper to determine session color based on duration
    private func sessionColor(for session: Session) -> Color {
        guard let duration = session.duration else { return .appAccent }
        
        if duration > 3600 { // More than 1 hour
            return .appSuccess
        } else if duration > 1800 { // More than 30 min
            return .appAccent
        } else {
            return .appSecondary
        }
    }
}

// MARK: - Simple Glassmorphic Card
struct GlassmorphicCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .blur(radius: 0.5)
                
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground).opacity(0.7))
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear,
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Session.self)
} 
