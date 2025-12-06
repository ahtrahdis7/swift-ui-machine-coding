//
//  Q1_TodoAppTry1App.swift
//  Q1-TodoAppTry1
//
//  Created by Sidhartha Mallick on 05/12/25.
//

import SwiftUI
import SwiftData

@main
struct Q1_TodoAppTry1App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TodoModel.self)
    }
}
