import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var size: CGFloat
    
    @State private var animateProgress = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background circle with subtle gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(UIColor.secondarySystemBackground),
                            Color(UIColor.tertiarySystemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Background track
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.1)
                .foregroundColor(Color.gray.opacity(0.3))
                .frame(width: size - 15, height: size - 15)
            
            // Progress circle with dynamic gradient
            Circle()
                .trim(from: 0.0, to: CGFloat(min(animateProgress ? self.progress : 0.0, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundStyle(progressGradient)
                .frame(width: size - 15, height: size - 15)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut(duration: 0.8), value: animateProgress)
            
            // Center Content
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size / 4.5, weight: .bold, design: .rounded))
                    .foregroundColor(progressTextColor)
                    .contentTransition(.numericText())
                
                Text("of 8h")
                    .font(.system(size: size / 8, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .opacity(animateProgress ? 1 : 0)
            .scaleEffect(animateProgress ? 1 : 0.8)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: animateProgress)
        }
        .frame(width: size, height: size)
        .onAppear {
            // Start animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateProgress = true
                
                // Start subtle pulse animation
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.02
                }
            }
        }
    }
    
    // Dynamic gradient based on progress
    private var progressGradient: LinearGradient {
        if progress >= 1.0 {
            // Completed gradient (green tones)
            return LinearGradient(
                colors: [
                    Color.appSuccess,
                    Color.appSuccess.opacity(0.8)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progress > 0.7 {
            // Almost there gradient (blue-green)
            return LinearGradient(
                colors: [.appAccent, .appSuccess.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // Standard gradient
            return LinearGradient(
                colors: [.appAccent, .appSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // Dynamic text color based on progress
    private var progressTextColor: Color {
        if progress >= 1.0 {
            return Color.appSuccess
        } else {
            return Color.primary
        }
    }
} 