//
//  ContentView.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    let environment: AppEnvironment
    @ObservedObject private var languageSpaceManager: LanguageSpaceManager
    @State private var selection = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(environment: AppEnvironment) {
        self.environment = environment
        _languageSpaceManager = ObservedObject(wrappedValue: environment.languageSpaceManager)
    }
    
    var body: some View {
        Group {
            if languageSpaceManager.activeSpace == nil {
                FirstLanguageSpaceView(
                    languageSpaceManager: environment.languageSpaceManager,
                    translationService: environment.translationService
                )
            } else {
                mainTabs
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selection) {
            DashboardView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                translationService: environment.translationService,
                languageSpaceManager: environment.languageSpaceManager,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                    Text("Today")
                }.tag(0)
            
            WordListView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                translationService: environment.translationService,
                languageSpaceManager: environment.languageSpaceManager,
                storeManager: environment.storeManager
            )
                .tabItem {
                    Image(systemName: "character.textbox")
                    Text("Words")
                }.tag(1)
            
            QuizView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                languageSpaceManager: environment.languageSpaceManager
            )
                .tabItem {
                    Image(systemName: "target")
                    Text("Practice")
                }.tag(2)
            
            StoryView(
                wordRepository: environment.wordRepository,
                storyRepository: environment.storyRepository,
                storyService: environment.storyService,
                storeManager: environment.storeManager,
                languageSpaceManager: environment.languageSpaceManager
            )
                .tabItem {
                    Image(systemName: "book.pages.fill")
                    Text("Stories")
                }.tag(3)
            
            SettingsView(
                wordRepository: environment.wordRepository,
                dataManager: environment.dataManager,
                userManager: environment.userManager,
                storeManager: environment.storeManager,
                translationService: environment.translationService,
                languageSpaceManager: environment.languageSpaceManager
            )
                .tabItem {
                    Image(systemName: "circle.grid.2x2.fill")
                    Text("More")
                }.tag(4)
        }
        .tint(Theme.Colors.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .sensoryFeedback(.selection, trigger: selection)
        .animation(reduceMotion ? nil : Theme.Motion.quick, value: selection)
    }
}

#Preview {
    ContentView(environment: AppEnvironment())
}
