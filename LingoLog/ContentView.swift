//
//  ContentView.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    let environment: AppEnvironment
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            DashboardView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                translationService: environment.translationService
            )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Today")
                }.tag(0)
            
            WordListView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                translationService: environment.translationService
            )
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Words")
                }.tag(1)
            
            QuizView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager
            )
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Quiz")
                }.tag(2)
            
            StoryView(
                wordRepository: environment.wordRepository,
                storyRepository: environment.storyRepository,
                storyService: environment.storyService,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "book.pages.fill")
                    Text("Stories")
                }.tag(3)
            
            SettingsView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }.tag(4)
        }
        .tint(Theme.Colors.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Theme.Colors.background, for: .tabBar)
    }
}

#Preview {
    ContentView(environment: AppEnvironment())
}
