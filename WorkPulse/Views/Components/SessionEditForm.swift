import SwiftUI

struct SessionEditForm: View {
    let session: Session
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showError = false
    
    var onSave: (Date, Date) -> Void
    var onCancel: () -> Void
    
    init(session: Session, onSave: @escaping (Date, Date) -> Void, onCancel: @escaping () -> Void) {
        self.session = session
        self.onSave = onSave
        self.onCancel = onCancel
        
        _startDate = State(initialValue: session.startTime)
        _endDate = State(initialValue: session.endTime ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Start Time") {
                    DatePicker("Start", selection: $startDate)
                        .datePickerStyle(.compact)
                }
                
                Section("End Time") {
                    DatePicker("End", selection: $endDate)
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if endDate > startDate {
                            onSave(startDate, endDate)
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .alert("Invalid Time Range", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text("End time must be after start time.")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SessionEditForm(
        session: Session(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        ),
        onSave: { _, _ in },
        onCancel: { }
    )
} 