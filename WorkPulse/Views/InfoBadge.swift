import SwiftUI

struct InfoBadge: View {
    var value: String
    var label: String
    var systemImage: String
    
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                    .foregroundColor(.appAccent)
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.5)
            
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 5)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: true, vertical: false)
                .opacity(appear ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeOut.delay(0.2)) {
                appear = true
            }
        }
    }
} 