//
//  StrongMeApp.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import SwiftUI

@main
struct StrongMeApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
