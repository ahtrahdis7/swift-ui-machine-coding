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
    func markComplete(id: Int)
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
    
    func add() {
        let index = allTodos.count
        let newTodo = TodoModel(id: index,text: "", description: "", type: .active)
        allTodos[index] = newTodo
        edit(id: index)
    }
    
    func remove(id: Int) {
        allTodos.removeValue(forKey: id)
    }
    
    func edit(id: Int) {
        state = .editing(index: id)
        if let editingTodo = allTodos[id] {
            editingText.update(newTodo: editingTodo)
            
            $editingText
//                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .sink { [weak self] value in
                    guard let self = self else { return }
                    allTodos[editingText.id] = editingText.copy()
                }
                .store(in: &cancellables)
        }
        
    }
    
    func markComplete(id: Int) {
        if allTodos[id] != nil {
            allTodos[id]?.type = .completed
        }
    }
    
    func updateFilter(filter: FilterType) {
        self.filter = filter
    }
    
    func stopEditing() {
        state = .view
    }
}

private extension TodoListViewModel {
//    func resetEdit() {
//        editingText.id = 0
//        editingText.te
//    }
}
