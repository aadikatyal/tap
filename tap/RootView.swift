//
//  RootView.swift
//  tap
//
//  Created by Aadi Katyal on 11/18/24.
//

import SwiftUI

struct RootView: View {
    @State private var userFirstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? "user"
    @State private var isAuthenticated: Bool = UserDefaults.standard.bool(forKey: "isAuthenticated")

    var body: some View {
        if isAuthenticated {
            TabView {
                // DashboardView as the default home screen
                DashboardView(firstName: $userFirstName, isAuthenticated: $isAuthenticated)
                    .tabItem {
                        Label("home", systemImage: "house.fill")
                    }
                
                // PaymentsView as a new tab
                PaymentsView()
                    .tabItem {
                        Label("payments", systemImage: "creditcard.fill")
                    }
            }
        } else {
            LoginView(isAuthenticated: $isAuthenticated, userFirstName: $userFirstName)
        }
    }
}
