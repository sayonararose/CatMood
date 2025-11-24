//
//  ContentView.swift
//  CatMood
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // 1 = Головна сторінка за замовчуванням
    @State private var selectedTab = 1
    
    init() {
        // Налаштування темного кольору для нижньої панелі
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        UITabBar.appearance().barTintColor = UIColor.black
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // --- Вкладка 1: Історія (Календар) ---
            HistoryView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Історія")
                }
                .tag(0)
            
            // --- Вкладка 2: Головна (Котик і ввід) ---
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Головна")
                }
                .tag(1)
            
            // --- Вкладка 3: Статистика (Графік) ---
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Статистика")
                }
                .tag(2)
        }
        .accentColor(.yellow) // Колір активної іконки
    }
}