//
//  ContentView.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            WordListView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Words")
                }
            
            QuizView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Quiz")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
