//
//  TodoModel.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftData

struct TodoModel {
    var id: Int
    var text: String
    var description: String
    var type: TodoType
    
    mutating func update(newTodo: TodoModel) {
        self.id = newTodo.id
        self.text = newTodo.text
        self.description = newTodo.description
        self.type = newTodo.type
    }
    
    func copy() -> TodoModel {
        return TodoModel(id: id, text: text, description: description, type: type)
    }
}
