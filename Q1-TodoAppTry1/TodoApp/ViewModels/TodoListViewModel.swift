//
//  TodoListViewModel.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation
import Combine
import SwiftData

enum TodoType: Codable {
    case active
    case completed
}

enum FilterType {
    case all
    case active
    case completed
}

enum TodoState {
    case editing(index: Int)
    case view
}

protocol TodoListViewModelProtocol: ObservableObject {
    func add()
    func remove(id: Int)
    func edit(id: Int)
    func toggleTodo(id: Int)
    func updateFilter(filter: FilterType)
    func stopEditing()
}

@MainActor
class TodoListViewModel: TodoListViewModelProtocol {
    
    @Published var state: TodoState = .view
    @Published var allTodos: [Int: TodoModel] = [:]
    @Published var filter = FilterType.all
    @Published var editingText = TodoModel(id: 0, text: "", type: .active)
    
    private var cancellables = Set<AnyCancellable>()
    private var nextId: Int = 1
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let startTime = Int(Date().timeIntervalSince1970)
        loadTodos()
        let endTime = Int(Date().timeIntervalSince1970)
        print("that's load time")
        print(endTime - startTime)
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        self.modelContext = newContext
        loadTodos()
    }
    
    private func loadTodos() {
        // Fetch all todos from SwiftData
        let descriptor = FetchDescriptor<TodoModel>(sortBy: [SortDescriptor(\.id)])
        if let todos = try? modelContext.fetch(descriptor) {
            // Populate the dictionary
            for todo in todos {
                allTodos[todo.id] = todo
                // Update nextId to be higher than any existing ID
                if todo.id >= nextId {
                    nextId = todo.id + 1
                }
            }
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func add() {
        // Generate unique ID using counter
        let index = nextId
        nextId += 1
        
        // Stop editing any current todo before adding a new one
        stopEditing()
        
        let newTodo = TodoModel(id: index, text: "", type: .active)
        allTodos[index] = newTodo
        
        // Insert into SwiftData context
        modelContext.insert(newTodo)
        saveContext()
        
        edit(id: index)
    }
    
    func remove(id: Int) {
        if let todo = allTodos[id] {
            // Remove from SwiftData context
            modelContext.delete(todo)
            saveContext()
        }
        allTodos.removeValue(forKey: id)
        cancellables.removeAll()
        editingText.update(newTodo: TodoModel(id: 0, text: "", type: .completed))
        print("removed")
    }
    
    func edit(id: Int) {
        // Clean up previous cancellables before starting a new edit
        cancellables.removeAll()
        
        state = .editing(index: id)
        if let editingTodo = allTodos[id] {
            editingText.update(newTodo: editingTodo)
            
            $editingText
                .filter { value in
                    print(value.id)
                    return value.id == 0 ? false: true
                }
                .sink { [weak self] value in
                    guard let self = self else { return }
                    // Update the todo in the dictionary (which is the same reference as in SwiftData)
                    if let existingTodo = allTodos[editingText.id] {
                        existingTodo.text = editingText.text
                        existingTodo.type = editingText.type
                        // SwiftData automatically tracks changes to @Model objects
                        // But we should save to persist
                        self.saveContext()
                    }
                }
                .store(in: &cancellables)
        }
        
    }
    
    func toggleTodo(id: Int) {
        if let todo = allTodos[id] {
            todo.type = todo.type == .active ? .completed : .active
            // SwiftData automatically tracks changes, but save to persist
            saveContext()
        }
            
        if editingText.id == id {
            editingText.type = editingText.type == .active ? .completed: .active
            editingText.update(newTodo: editingText)
        }
    }
    
    func updateFilter(filter: FilterType) {
        self.filter = filter
    }
    
    func stopEditing() {
        cancellables.removeAll()
        state = .view
    }
}
