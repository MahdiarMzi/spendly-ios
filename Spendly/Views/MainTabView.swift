//
//  MainTabView.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AddExpenseView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            RecurringView()
                .tabItem {
                    Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
                }
            ExpenseListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            IncomeView()
                .tabItem {
                    Label("Income", systemImage: "arrow.down.circle.fill")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(.dark)
    }
}
