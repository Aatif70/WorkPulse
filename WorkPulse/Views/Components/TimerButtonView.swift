import SwiftUI

struct TimerButtonView: View {
    var isRunning: Bool
    var action: () -> Void
    
    @State private var animateScale = false
    @State private var animatePulse = false
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateScale = true
            }
            
            // Visual feedback
            generateHapticFeedback()
            
            // Rotate animation for state change
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rotation += 180
            }
            
            action()
            
            // Reset scale after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animateScale = false
                }
            }
        }) {
            ZStack {
                // Background glow
                Circle()
                    .fill(isRunning ? Color.appError.opacity(0.15) : Color.appSuccess.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                
                // Outer glow circle
                Circle()
                    .fill(isRunning ? Color.appError.opacity(0.3) : Color.appAccent.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                // Main button gradient circle
                Circle()
                    .fill(isRunning ? Color.redGradient : Color.blueGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: isRunning ? Color.appError.opacity(0.4) : Color.appAccent.opacity(0.4), radius: 10, x: 0, y: 5)
                
                // Icon
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
                
                // Text label
                Text(isRunning ? "STOP" : "START")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isRunning ? Color.appError : Color.appAccent)
                    )
                    .offset(y: 45)
            }
            .scaleEffect(animateScale ? 1.1 : 1.0)
            .rotationEffect(.degrees(rotation/2))
        }
        .buttonStyle(.plain)
        .onAppear {
            // Start pulsing animation if timer is running
            if isRunning {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            }
        }
        .onChange(of: isRunning) { oldValue, newValue in
            if newValue {
                // Start pulsing when timer starts
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            } else {
                // Stop pulsing when timer stops
                withAnimation {
                    animatePulse = false
                }
            }
        }
    }
    
    private func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: isRunning ? .heavy : .medium)
        generator.impactOccurred()
        
        // Add additional tap for stopping (feels more definitive)
        if isRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let secondGenerator = UIImpactFeedbackGenerator(style: .rigid)
                secondGenerator.impactOccurred()
            }
        }
    }
}

#Preview {
    VStack {
        TimerButtonView(isRunning: false) {}
        TimerButtonView(isRunning: true) {}
    }
} 