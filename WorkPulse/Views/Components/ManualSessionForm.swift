import SwiftUI

struct ManualSessionForm: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showError = false
    
    var onSave: (Date, Date) -> Void
    var onCancel: () -> Void
    
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
            .navigationTitle("Add Manual Session")
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
    ManualSessionForm(
        onSave: { _, _ in },
        onCancel: { }
    )
} 