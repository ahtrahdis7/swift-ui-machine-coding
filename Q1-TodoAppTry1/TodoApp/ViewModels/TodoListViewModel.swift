//
//  TodoListViewModel.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation
import Combine

enum TodoType {
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
    @Published var editingText = TodoModel(id: 0, text: "", description: "", type: .active)
    
    private var cancellables = Set<AnyCancellable>()
    private var nextId: Int = 1
    
    func add() {
        // Generate unique ID using counter
        let index = nextId
        nextId += 1
        
        // Stop editing any current todo before adding a new one
        stopEditing()
        
        let newTodo = TodoModel(id: index, text: "", description: "", type: .active)
        allTodos[index] = newTodo
        edit(id: index)
    }
    
    func remove(id: Int) {
        allTodos.removeValue(forKey: id)
        cancellables.removeAll()
        editingText.update(newTodo: TodoModel(id: 0, text: "", description: "", type: .completed))
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
                    print(value)
                    return value.id == 0 ? false: true
                }
                .sink { [weak self] value in
                    guard let self = self else { return }
                    allTodos[editingText.id] = editingText.copy()
                }
                .store(in: &cancellables)
        }
        
    }
    
    func toggleTodo(id: Int) {
        if var todo = allTodos[id] {
            todo.type = todo.type == .active ? .completed : .active
            allTodos[id] = todo
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
