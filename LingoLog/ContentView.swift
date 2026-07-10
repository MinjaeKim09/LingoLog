//
//  ContentView.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    let environment: AppEnvironment
    
    var body: some View {
        TabView {
            DashboardView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                translationService: environment.translationService
            )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            WordListView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                translationService: environment.translationService
            )
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Words")
                }
            
            QuizView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager
            )
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Quiz")
                }
            
            StoryView(
                wordRepository: environment.wordRepository,
                storyRepository: environment.storyRepository,
                storyService: environment.storyService,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "book.pages.fill")
                    Text("Stories")
                }
            
            SettingsView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(Theme.Colors.accent)
    }
}

#Preview {
    ContentView(environment: AppEnvironment())
}
