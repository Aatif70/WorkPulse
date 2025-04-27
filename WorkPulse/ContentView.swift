//
//  ContentView.swift
//  WorkPulse
//
//  Created by Aatif Ahmed on 4/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TimesheetViewModel?
    
    var body: some View {
        HomeView(viewModel: viewModel)
            .appTheme()
            .preferredColorScheme(ColorScheme.light)
            .onAppear {
                if viewModel == nil {
                    viewModel = TimesheetViewModel(modelContext: modelContext)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Session.self)
}
