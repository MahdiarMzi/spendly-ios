//
//  SpendlyApp.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//

import SwiftUI

@main
struct SpendlyApp: App {
    @StateObject var store = ExpenseStore()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if showSplash && store.userProfile?.onboardingComplete == true {
                SplashView(name: store.userProfile?.name ?? "") {
                    withAnimation {
                        showSplash = false
                    }
                }
            } else if store.userProfile?.onboardingComplete == true {
                MainTabView()
                    .environmentObject(store)
                    .onAppear {
                        NotificationManager.shared.requestPermission()
                        AINotificationService.shared.scheduleWeeklyChecks()
                    }
            } else {
                OnboardingView()
                    .environmentObject(store)
            }
        }
    }
}
