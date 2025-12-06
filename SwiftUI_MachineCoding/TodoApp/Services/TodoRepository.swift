//
//  TodoRepository.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation
import SwiftData

/// Protocol defining data access operations for TodoModel
protocol TodoRepository {
    /// Get the maximum ID from all todos in the database
    func getMaxId() -> Int
    
    /// Fetch a page of todos with pagination
    /// - Parameters:
    ///   - offset: Starting position for pagination
    ///   - limit: Maximum number of items to fetch
    /// - Returns: Array of TodoModel items
    func fetchPage(offset: Int, limit: Int) throws -> [TodoModel]
    
    /// Check if there are more todos beyond the given offset
    /// - Parameter offset: Current offset position
    /// - Returns: True if more todos exist
    func hasMore(offset: Int) -> Bool
    
    /// Insert a new todo into the database
    /// - Parameter todo: The todo to insert
    func insert(_ todo: TodoModel) throws
    
    /// Delete a todo from the database
    /// - Parameter todo: The todo to delete
    func delete(_ todo: TodoModel) throws
    
    /// Save all pending changes to the database
    func save() throws
}

/// SwiftData implementation of TodoRepository
@MainActor
class SwiftDataTodoRepository: TodoRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getMaxId() -> Int {
        var descriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        do {
            if let maxTodo = try modelContext.fetch(descriptor).first {
                return maxTodo.id + 1
            } else {
                return 1  // No todos exist yet
            }
        } catch {
            print("Failed to get max ID: \(error)")
            return 1
        }
    }
    
    func fetchPage(offset: Int, limit: Int) throws -> [TodoModel] {
        var descriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        return try modelContext.fetch(descriptor)
    }
    
    func hasMore(offset: Int) -> Bool {
        var testDescriptor = FetchDescriptor<TodoModel>(
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        testDescriptor.fetchOffset = offset
        testDescriptor.fetchLimit = 1
        
        do {
            let testTodos = try modelContext.fetch(testDescriptor)
            return !testTodos.isEmpty
        } catch {
            return false
        }
    }
    
    func insert(_ todo: TodoModel) throws {
        modelContext.insert(todo)
        try save()
    }
    
    func delete(_ todo: TodoModel) throws {
        modelContext.delete(todo)
        try save()
    }
    
    func save() throws {
        guard modelContext.hasChanges else { return }
        try modelContext.save()
    }
}
