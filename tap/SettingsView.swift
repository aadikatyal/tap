//
//  SettingsView.swift
//  tap
//
//  Created by Aadi Katyal on 11/10/24.
//


import SwiftUI
import CloudKit

struct SettingsView: View {
    @Binding var firstName: String
    @Binding var isAuthenticated: Bool
    @State private var showNameEdit = false
    @State private var showLogOutConfirmation = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("profile")) {
                    Button(action: {
                        showNameEdit = true
                    }) {
                        HStack {
                            Text("name")
                            Spacer()
                            Text(firstName)
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showNameEdit) {
                        NameEditView(firstName: $firstName)
                    }
                }
                Section {
                    Button("log out") {
                        showLogOutConfirmation = true
                    }
                    .alert("are you sure you want to log out?", isPresented: $showLogOutConfirmation) {
                        Button("cancel", role: .cancel) {}
                        Button("log out", role: .destructive) {
                            handleLogOut()
                        }
                    }
                }
            }
            .navigationTitle("settings")
        }
    }

    private func handleLogOut() {
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "userID")
        UserDefaults.standard.removeObject(forKey: "userFirstName")
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.synchronize()

        // Update state variables
        isAuthenticated = false
        firstName = "user"
    }
}
