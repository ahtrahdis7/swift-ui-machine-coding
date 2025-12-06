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
    private var modelContext: ModelContext
    private let pageSize: Int = 100
    private var loadedCount: Int = 0
    
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
        // First, calculate nextId by finding the MAX ID from ALL todos in database
        // This prevents overwriting existing todos when creating new ones
        calculateNextId()
        
        // Load initial page of todos
        loadPage(offset: 0, limit: pageSize)
    }
    
    private func calculateNextId() {
        // Query to find the maximum ID from ALL todos (not just loaded ones)
        var descriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        descriptor.fetchLimit = 1  // We only need the max ID
        
        do {
            if let maxTodo = try modelContext.fetch(descriptor).first {
                nextId = maxTodo.id + 1
            } else {
                nextId = 1  // No todos exist yet
            }
        } catch {
            print("Failed to calculate nextId: \(error)")
            nextId = 1
        }
    }
    
    private func loadPage(offset: Int, limit: Int) {
        var descriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        do {
            let todos = try modelContext.fetch(descriptor)
            
            // Add todos to dictionary (skip if already loaded)
            var newTodosCount = 0
            for todo in todos {
                if allTodos[todo.id] == nil {
                    allTodos[todo.id] = todo
                    newTodosCount += 1
                }
            }
            
            // Update loaded count based on offset + what we actually fetched
            // This represents how many items we've attempted to load from the database
            loadedCount = offset + todos.count
            
            // Check if there are more todos to load
            checkIfHasMore()
            
        } catch {
            print("Failed to load todos: \(error)")
        }
    }
    
    private func checkIfHasMore() {
        // Check if there are more todos by trying to fetch one item beyond what we've loaded
        var testDescriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        testDescriptor.fetchOffset = loadedCount
        testDescriptor.fetchLimit = 1
        
        do {
            let testTodos = try modelContext.fetch(testDescriptor)
            hasMoreTodos = !testTodos.isEmpty
        } catch {
            hasMoreTodos = false
        }
    }
    
    func loadMore() {
        guard hasMoreTodos && !isLoadingMore else { return }
        
        isLoadingMore = true
        
        // Load next page
        loadPage(offset: loadedCount, limit: pageSize)
        
        isLoadingMore = false
    }
    
    private func saveContext() {
        // Batch saves: Only save if there are pending changes
        guard modelContext.hasChanges else { return }
        
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
        // Note: loadedCount tracks pagination position, not total todos
        // New todos are added directly, not via pagination
        
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
        // Note: loadedCount represents fetch position, not dictionary size
        // So we don't decrement it, but we recheck if there are more todos
        cancellables.removeAll()
        editingText.update(newTodo: TodoModel(id: 0, text: "", type: .completed))
        
        // Recheck if there are more todos after deletion
        checkIfHasMore()
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
