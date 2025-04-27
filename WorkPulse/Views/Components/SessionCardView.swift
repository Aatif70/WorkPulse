import SwiftUI

struct SessionCardView: View {
    let session: Session
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    @State private var appear = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: session.startTime))
                        .font(.headline)
                        .foregroundStyle(Color.appAccent)
                }
                
                Spacer()
                
                if session.isManualEntry {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                        
                        Text("Manual Entry")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appWarning.opacity(0.2))
                    .foregroundColor(.appWarning)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            Divider()
                .background(Color.appAccent.opacity(0.1))
                .scaleEffect(x: appear ? 1 : 0.3, anchor: .leading)
                .opacity(appear ? 1 : 0)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("End Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let endTime = session.endTime {
                        Text(dateFormatter.string(from: endTime))
                            .font(.headline)
                    } else {
                        Text("In Progress")
                            .font(.headline)
                            .foregroundColor(.appSuccess)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .trailing) {
                        // Background pill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.appAccent.opacity(0.2), .appSecondary.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80, height: 24)
                        
                        // Duration text
                        Text(session.formattedDuration)
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundColor(.appAccent)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.appAccent.opacity(0.2), .appSecondary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.appAccent)
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Session", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete Session", systemImage: "trash")
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                appear = true
            }
        }
    }
}

#Preview {
    SessionCardView(
        session: Session(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            isManualEntry: false
        ),
        onDelete: {},
        onEdit: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
} 