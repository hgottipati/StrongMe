//
//  ContentView.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workouts Tab
            WorkoutsView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Workouts")
                }
                .tag(0)
            
            // Exercises Tab
            ExercisesView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Exercises")
                }
                .tag(1)
            
                // Progress Tab
                ProgressStatsView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(2)
            
            // Profile Tab
            ProfileView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}
