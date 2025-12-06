//
//  TodoAppMainView.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftUI
import SwiftData

struct TodoAppMainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TodoListViewModel
    
    init() {
        // Create a temporary container for initialization
        // This will be replaced with the actual context in onAppear
        let container = try! ModelContainer(for: TodoModel.self)
        let tempContext = ModelContext(container)
        _viewModel = StateObject(wrappedValue: TodoListViewModel(modelContext: tempContext))
    }
    
    var body: some View {
        TodoListView(viewModel: viewModel)
            .navigationTitle("Todo List")
            .onAppear {
                // Update the viewModel with the actual environment context
                viewModel.updateModelContext(modelContext)
            }
    }
}

#Preview {
    TodoAppMainView()
}
