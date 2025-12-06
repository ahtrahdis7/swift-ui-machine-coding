//
//  TodoListView.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // filter view
                HStack(spacing: 12) {
                    FilterButton(
                        title: "All",
                        isSelected: viewModel.filter == .all,
                        action: { viewModel.updateFilter(filter: .all) }
                    )
                    FilterButton(
                        title: "Active",
                        isSelected: viewModel.filter == .active,
                        action: { viewModel.updateFilter(filter: .active) }
                    )
                    FilterButton(
                        title: "Completed",
                        isSelected: viewModel.filter == .completed,
                        action: { viewModel.updateFilter(filter: .completed) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white)
                
                List {
                ForEach(viewModel.allTodos
                    .filter { id, item in
                        switch viewModel.filter {
                        case .all:
                            return true
                        case .active:
                            return item.type == .active
                        case .completed:
                            return item.type == .completed
                        }
                    }
                    .sorted(by: { $0.key < $1.key }), id: \.key) { id, item in
                        HStack {
                            Button(action: {
                                viewModel.toggleTodo(id: id)
                            }) {
                                Image(systemName: item.type == .completed ? "checkmark.square.fill" : "square")
                                    .foregroundColor(item.type == .completed ? .blue : .gray)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)

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
                                    .strikethrough(item.type == .completed)
                                    .onSubmit {
                                        viewModel.stopEditing()
                                    }
                                
                            } else {
                                if item.type == .completed {
                                    Text(item.text)
                                        .strikethrough()
                                } else {
                                    Text(item.text)
                                }
                                
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive, action: {
                                viewModel.remove(id: id)
                            }){
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .gesture(
                            // Only apply tap gesture when not editing this item
                            TapGesture()
                                .onEnded { _ in
                                    if case .editing(let editingId) = viewModel.state,
                                        editingId == id {
                                        // Already editing this item, don't do anything
                                    } else {
                                        viewModel.edit(id: id)
                                    }
                                }
                        )
                }
                
                ProgressView()
                    .onAppear {
                        viewModel.loadMore()
                    }
                }
                .background(.white)
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
        .background(.white)
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = try! ModelContainer(for: TodoModel.self)
    let context = ModelContext(container)
    TodoListView(viewModel: TodoListViewModel(modelContext: context))
}
