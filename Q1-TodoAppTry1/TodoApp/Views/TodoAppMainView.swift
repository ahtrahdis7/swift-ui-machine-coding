//
//  TodoAppMainView.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftUI

struct TodoAppMainView: View {
    @StateObject var viewModel = TodoListViewModel()
    
    var body: some View {
        TodoListView(viewModel: viewModel)
            .navigationTitle("Todo List")
    }
}

#Preview {
    TodoAppMainView()
}
