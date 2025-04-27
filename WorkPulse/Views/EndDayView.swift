import SwiftUI

struct EndDayView: View {
    var viewModel: TimesheetViewModel
    @Binding var isPresented: Bool
    @State private var showAnimation = false
    @State private var isDayEnded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Animated celebration illustration
                    celebrationView
                        .frame(height: 180)
                        .padding(.top, 20)
                    
                    // Stats cards with glassmorphism
                    statsCardsView
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Status message
                    if viewModel.isDayEnded {
                        Text("Your work day has been marked as complete")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    actionButtonsView
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle("Day Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                // Get initial state
                isDayEnded = viewModel.isDayEnded
                
                withAnimation {
                    showAnimation = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var celebrationView: some View {
        ZStack {
            // Background circles
            backgroundCircles
            
            // Completion icon
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.appSuccess)
                    .opacity(showAnimation ? 1 : 0)
                    .scaleEffect(showAnimation ? 1 : 0.5)
                    .shadow(color: .appSuccess.opacity(0.5), radius: 10, x: 0, y: 0)
                
                Text(viewModel.isDayEnded ? "Day Complete!" : "Day Summary")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : 20)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showAnimation)
        }
    }
    
    private var backgroundCircles: some View {
        ZStack {
            // First circle
            CircleView(
                colors: [.appAccent, .appSecondary.opacity(0.7)],
                size: 140,
                offset: CGPoint(x: 20, y: -20),
                delay: 0
            )
            
            // Second circle
            CircleView(
                colors: [.appSecondary, .appSuccess.opacity(0.7)],
                size: 100,
                offset: CGPoint(x: -40, y: 30),
                delay: 0.2
            )
            
            // Third circle
            CircleView(
                colors: [.appSuccess, .appAccent.opacity(0.7)],
                size: 120,
                offset: CGPoint(x: 60, y: -40),
                delay: 0.4
            )
        }
    }
    
    private var statsCardsView: some View {
        VStack(spacing: 15) {
            // Total work time
            DaySummaryCard(
                title: "Total Work Time",
                value: viewModel.formattedTodayTotalTime,
                icon: "clock.fill",
                color: .appAccent
            )
            
            // Session count
            DaySummaryCard(
                title: "Sessions Completed",
                value: "\(viewModel.todaySessions.count)",
                icon: "list.bullet.clipboard.fill",
                color: .appSecondary
            )
            
            // Average session
            if let avgSession = calculateAverageSessionTime(viewModel: viewModel) {
                DaySummaryCard(
                    title: "Average Session",
                    value: avgSession,
                    icon: "timer",
                    color: .appSuccess
                )
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 15) {
            // Share button
            Button {
                // Export functionality to be implemented
            } label: {
                Label("Share Day Report", systemImage: "square.and.arrow.up")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.appAccent, .appSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            // End/Resume Day button
            if viewModel.isDayEnded {
                // Resume Day button
                Button {
                    viewModel.resumeDay()
                    isPresented = false
                } label: {
                    Label("Resume Working", systemImage: "play.circle")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.appSuccess)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.appSuccess.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.appSuccess.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            } else {
                // End Day button
                Button {
                    viewModel.endDay()
                    isDayEnded = true
                } label: {
                    Label("End Work Day", systemImage: "moon.stars")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            
            // Close button
            Button {
                isPresented = false
            } label: {
                Text("Close")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func calculateAverageSessionTime(viewModel: TimesheetViewModel) -> String? {
        let sessions = viewModel.todaySessions
        guard !sessions.isEmpty else { return nil }
        
        let durations = sessions.compactMap { $0.duration }
        guard !durations.isEmpty else { return nil }
        
        let totalTime = durations.reduce(0, +)
        let averageTime = totalTime / Double(durations.count)
        
        // Format as hours & minutes for average
        let hours = Int(averageTime) / 3600
        let minutes = Int(averageTime) / 60 % 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
}

// MARK: - Supporting Views

struct CircleView: View {
    var colors: [Color]
    var size: CGFloat
    var offset: CGPoint
    var delay: Double
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size)
            .offset(x: offset.x, y: offset.y)
            .opacity(0.4)
            .blur(radius: 20)
            .scaleEffect(animate ? 1.1 : 0.9)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

struct DaySummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
} 