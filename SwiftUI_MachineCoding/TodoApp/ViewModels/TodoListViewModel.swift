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
    func loadMore()
}

@MainActor
class TodoListViewModel: TodoListViewModelProtocol {
    
    @Published var state: TodoState = .view
    @Published var allTodos: [Int: TodoModel] = [:]
    @Published var filter = FilterType.all
    @Published var editingText = TodoModel(id: 0, text: "", type: .active)
    @Published var hasMoreTodos: Bool = false
    @Published var isLoadingMore: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var nextId: Int = 1
    private let repository: TodoRepository
    private let pageSize: Int = 100
    private var loadedCount: Int = 0
    
    init(repository: TodoRepository) {
        self.repository = repository
        let startTime = Int(Date().timeIntervalSince1970)
        loadTodos()
        let endTime = Int(Date().timeIntervalSince1970)
        print("that's load time")
        print(endTime - startTime)
    }
    
    // Convenience initializer for ModelContext (creates repository internally)
    convenience init(modelContext: ModelContext) {
        self.init(repository: SwiftDataTodoRepository(modelContext: modelContext))
    }
    
    // Note: Repository is immutable after initialization
    // If you need to update the context, recreate the ViewModel with a new repository
    
    private func loadTodos() {
        // First, calculate nextId by finding the MAX ID from ALL todos in database
        // This prevents overwriting existing todos when creating new ones
        nextId = repository.getMaxId()
        
        // Load initial page of todos
        loadPage(offset: 0, limit: pageSize)
    }
    
    private func loadPage(offset: Int, limit: Int) {
        do {
            let todos = try repository.fetchPage(offset: offset, limit: limit)
            
            // Add todos to dictionary (skip if already loaded)
            for todo in todos {
                if allTodos[todo.id] == nil {
                    allTodos[todo.id] = todo
                }
            }
            
            // Update loaded count based on offset + what we actually fetched
            // This represents how many items we've attempted to load from the database
            loadedCount = offset + todos.count
            
            // Check if there are more todos to load
            hasMoreTodos = repository.hasMore(offset: loadedCount)
            
        } catch {
            print("Failed to load todos: \(error)")
        }
    }
    
    func loadMore() {
        guard hasMoreTodos && !isLoadingMore else { return }
        
        isLoadingMore = true
        loadPage(offset: loadedCount, limit: pageSize)
        isLoadingMore = false
    }
    
    func add() {
        // Generate unique ID using counter
        let index = nextId
        nextId += 1
        
        // Stop editing any current todo before adding a new one
        stopEditing()
        
        let newTodo = TodoModel(id: index, text: "", type: .active)
        allTodos[index] = newTodo
        // Note: loadedCount tracks pagination position, not total todos
        // New todos are added directly, not via pagination
        
        // Insert into repository
        do {
            try repository.insert(newTodo)
        } catch {
            print("Failed to add todo: \(error)")
        }
        
        edit(id: index)
    }
    
    func remove(id: Int) {
        if let todo = allTodos[id] {
            // Remove from repository
            do {
                try repository.delete(todo)
            } catch {
                print("Failed to remove todo: \(error)")
            }
        }
        allTodos.removeValue(forKey: id)
        // Note: loadedCount represents fetch position, not dictionary size
        // So we don't decrement it, but we recheck if there are more todos
        cancellables.removeAll()
        editingText.update(newTodo: TodoModel(id: 0, text: "", type: .completed))
        
        // Recheck if there are more todos after deletion
        hasMoreTodos = repository.hasMore(offset: loadedCount)
        print("removed")
    }
    
    func edit(id: Int) {
        // Clean up previous cancellables before starting a new edit
        cancellables.removeAll()
        
        state = .editing(index: id)
        if let editingTodo = allTodos[id] {
            editingText.update(newTodo: editingTodo)
            
            $editingText
                .debounce(for: 0.05, scheduler: DispatchQueue.main)
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
                        // Save changes through repository
                        do {
                            try self.repository.save()
                        } catch {
                            print("Failed to save todo changes: \(error)")
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
    }
    
    func toggleTodo(id: Int) {
        if let todo = allTodos[id] {
            todo.type = todo.type == .active ? .completed : .active
            // Save changes through repository
            do {
                try repository.save()
            } catch {
                print("Failed to save todo toggle: \(error)")
            }
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
