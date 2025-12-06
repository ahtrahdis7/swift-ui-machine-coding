//
//  TodoModel.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftData

@Model
final class TodoModel {
    var id: Int
    var text: String
    var type: TodoType
    
    init(id: Int, text: String, type: TodoType) {
        self.id = id
        self.text = text
        self.type = type
    }
    
    func update(newTodo: TodoModel) {
        self.id = newTodo.id
        self.text = newTodo.text
        self.type = newTodo.type
    }
    
    func copy() -> TodoModel {
        return TodoModel(id: id, text: text, type: type)
    }
}
