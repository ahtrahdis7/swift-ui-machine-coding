//
//  TodoListView.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftUI

struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.allTodos.sorted(by: { $0.key < $1.key }), id: \.key) { id, item in
                    HStack {
                        Text(String(id))
                        switch viewModel.state {
                        case .editing(_):
                            if viewModel.editingText.id == item.id {
                                TextField("Enter text", text: $viewModel.editingText.text)
                                    .textFieldStyle(.automatic)
                                    .focused($isTextFieldFocused)
                                    .onAppear {
                                        // Use async to ensure focus happens after view appears
                                        DispatchQueue.main.async {
                                            isTextFieldFocused = true
                                        }
                                    }
                                    .onSubmit {
                                        viewModel.stopEditing()
                                    }
                                
                            } else {
                                Text(item.text)
                            }
                        case .view:
                            Text(item.text)
                        }
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .gesture(
                        // Only apply tap gesture when not editing this item
                        TapGesture()
                            .onEnded { _ in
                                if case .editing(let editingId) = viewModel.state, editingId == id {
                                    // Already editing this item, don't do anything
                                } else {
                                    print(id)
                                    viewModel.edit(id: id)
                                }
                            }
                    )
                }
            }
            
            // Floating glass button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.add()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 56, height: 56)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                    
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            )
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Stop editing when tapping outside list items
                    // This will cause TextField to lose focus, which triggers onChange above
                    if case .editing = viewModel.state {
                        isTextFieldFocused = false
                    }
                }
        )
    }
}

#Preview {
    TodoListView(viewModel: TodoListViewModel())
}
