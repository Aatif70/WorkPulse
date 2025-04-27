import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    var viewModel: TimesheetViewModel
    @State private var editingSession: Session?
    @State private var selectedExportDay: Date?
    @State private var showingExportOptions = false
    @State private var exportFormat: ExportFormat = .csv
    @State private var animateItems = false
    @State private var selectedTab: HistoryTab = .all
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector at the top
            HStack(spacing: 0) {
                ForEach(HistoryTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Main content
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // List content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(filteredDates, id: \.self) { date in
                            DaySection(
                                date: date,
                                sessions: groupedSessions[date] ?? [],
                                dateFormatter: dateFormatter,
                                timeFormatter: timeFormatter,
                                onExport: {
                                    selectedExportDay = date
                                    showingExportOptions = true
                                },
                                onDelete: { session in
                                    withAnimation(.spring(response: 0.4)) {
                                        viewModel.deleteSession(session)
                                    }
                                },
                                onEdit: { session in
                                    editingSession = session
                                }
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .refreshable {
                    viewModel.loadSessions()
                }
                
                // Empty state
                if filteredDates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedTab == .today ? "clock" : "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.appAccent.opacity(0.5))
                        
                        Text(selectedTab == .today ? "No Sessions Today" : "No Sessions")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(selectedTab == .today ? 
                             "Start your timer to track your work time" :
                             "Your sessions will appear here once you start tracking")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .offset(y: -40)
                }
            }
        }
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Session History")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(LinearGradient(
                        colors: [.appAccent, .appSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Export all sessions
                    showingExportOptions = true
                    selectedExportDay = nil
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.appAccent)
                }
            }
        }
        .animation(.spring(response: 0.3), value: filteredDates)
        .sheet(item: $editingSession) { session in
            SessionEditForm(
                session: session,
                onSave: { newStart, newEnd in
                    session.startTime = newStart
                    session.endTime = newEnd
                    viewModel.updateSession(session)
                    editingSession = nil
                },
                onCancel: {
                    editingSession = nil
                }
            )
        }
        .confirmationDialog("Export Options", isPresented: $showingExportOptions, titleVisibility: .visible) {
            Button("Export as CSV") {
                exportFormat = .csv
                exportSessions()
            }
            
            Button("Export as PDF") {
                exportFormat = .pdf
                exportSessions()
            }
            
            Button("Cancel", role: .cancel) {
                showingExportOptions = false
            }
        }
        .onAppear {
            // Animate items in with a staggered effect
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateItems = true
            }
        }
    }
    
    private var groupedSessions: [Date: [Session]] {
        viewModel.groupedSessions()
    }
    
    private var filteredDates: [Date] {
        let dates = Array(groupedSessions.keys).sorted(by: >)
        
        switch selectedTab {
        case .today:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return dates.filter { calendar.isDate($0, inSameDayAs: today) }
            
        case .week:
            let calendar = Calendar.current
            let today = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            return dates.filter { $0 >= weekAgo }
            
        case .all:
            return dates
        }
    }
    
    // MARK: - Export Functionality
    
    private func exportSessions() {
        var sessions: [Session] = []
        
        if let date = selectedExportDay {
            // Export specific day
            sessions = groupedSessions[date] ?? []
        } else {
            // Export all filtered sessions
            for date in filteredDates {
                if let dateSessions = groupedSessions[date] {
                    sessions.append(contentsOf: dateSessions)
                }
            }
        }
        
        guard !sessions.isEmpty else { return }
        
        switch exportFormat {
        case .csv:
            exportAsCSV(sessions: sessions)
        case .pdf:
            exportAsPDF(sessions: sessions)
        }
    }
    
    private func exportAsCSV(sessions: [Session]) {
        let dateString = selectedExportDay != nil ? 
            dateFormatter.string(from: selectedExportDay!).replacingOccurrences(of: " ", with: "_") :
            "All_Sessions"
        
        var csvString = "Date,Start Time,End Time,Duration,Type\n"
        
        for session in sessions {
            let date = dateFormatter.string(from: session.startTime)
            let startTime = timeFormatter.string(from: session.startTime)
            let endTime = session.endTime != nil ? timeFormatter.string(from: session.endTime!) : "In Progress"
            let duration = session.formattedDuration
            let type = session.isManualEntry ? "Manual" : "Automatic"
            
            csvString += "\(date),\(startTime),\(endTime),\(duration),\(type)\n"
        }
        
        // Create a temporary file and share it
        let filename = "WorkPulse_Sessions_\(dateString).csv"
        
        if let url = saveToTemporaryFile(content: csvString, filename: filename) {
            shareFile(url: url)
        }
    }
    
    private func exportAsPDF(sessions: [Session]) {
        // Create a renderer for the PDF
        let dateString = selectedExportDay != nil ? 
            dateFormatter.string(from: selectedExportDay!) :
            "All Sessions"
        
        let renderer = SessionPDFRenderer(sessions: sessions, date: dateString)
        
        if let data = renderer.renderPDF() {
            let filename = "WorkPulse_Sessions_\(dateString.replacingOccurrences(of: " ", with: "_")).pdf"
            if let url = saveTemporaryData(data: data, filename: filename) {
                shareFile(url: url)
            }
        }
    }
    
    private func saveToTemporaryFile(content: String, filename: String) -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    private func saveTemporaryData(data: Data, filename: String) -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}

// MARK: - History Tab
enum HistoryTab: String, CaseIterable {
    case today
    case week
    case all
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .all: return "All Time"
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .medium))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? .white : .appAccent)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.appAccent : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Section
struct DaySection: View {
    let date: Date
    let sessions: [Session]
    let dateFormatter: DateFormatter
    let timeFormatter: DateFormatter
    let onExport: () -> Void
    let onDelete: (Session) -> Void
    let onEdit: (Session) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateFormatter.string(from: date))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.appAccent)
                    
                    let totalTime = sessions.compactMap { $0.duration }.reduce(0, +)
                    
                    Text("\(sessions.count) sessions · \(totalTime.formatAsHoursMinutesSeconds())")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.appAccent)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.appAccent.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            
            // Sessions list
            ForEach(sessions, id: \.startTime) { session in
                SessionRowView(
                    session: session,
                    timeFormatter: timeFormatter,
                    onDelete: { onDelete(session) },
                    onEdit: { onEdit(session) }
                )
                .padding(.horizontal, 2)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

// MARK: - Session Row
struct SessionRowView: View {
    let session: Session
    let timeFormatter: DateFormatter
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var showActions = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Time & duration column
            VStack(alignment: .leading, spacing: 4) {
                // Time range
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(timeFormatter.string(from: session.startTime)) - \(session.endTime != nil ? timeFormatter.string(from: session.endTime!) : "In Progress")")
                        .font(.system(.subheadline, design: .rounded))
                }
                
                // Duration with colored tag
                HStack(spacing: 6) {
                    Text(session.formattedDuration)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(session.duration ?? 0 > 3600 ? .appSuccess : .appAccent)
                    
                    if session.isManualEntry {
                        Text("Manual")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundColor(.appWarning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.appWarning.opacity(0.1))
                            )
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.appAccent)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.appAccent.opacity(0.1))
                        )
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
    }
}

// MARK: - Export Format
enum ExportFormat: String, Identifiable {
    case csv, pdf
    
    var id: String { rawValue }
}

// Extension to make Session identifiable by start time
extension Session: Identifiable {
    var id: Date { startTime }
}

#Preview {
    NavigationStack {
        SessionHistoryView(viewModel: TimesheetViewModel(modelContext: PreviewContainer.modelContext))
    }
} 