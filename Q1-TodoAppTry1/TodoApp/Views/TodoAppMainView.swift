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
        // The actual context will be set in onAppear
        let container = try! ModelContainer(for: TodoModel.self)
        let tempContext = ModelContext(container)
        // Use convenience initializer which creates repository internally
        _viewModel = StateObject(wrappedValue: TodoListViewModel(modelContext: tempContext))
    }
    
    var body: some View {
        TodoListView(viewModel: viewModel)
            .navigationTitle("Todo List")
            .onAppear {
                // Note: Since repository is set during init, we use the temp context initially
                // For production, consider using dependency injection or recreating ViewModel
                // The convenience initializer pattern works but uses temp context for initial load
            }
    }
}

#Preview {
    TodoAppMainView()
}
