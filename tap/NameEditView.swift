//
//  NameEditView.swift
//  tap
//
//  Created by Aadi Katyal on 11/10/24.
//


import SwiftUI
import CloudKit

struct NameEditView: View {
    @Binding var firstName: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("enter your name", text: $firstName)
                .navigationBarTitle("edit name", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    NSUbiquitousKeyValueStore.default.set(firstName, forKey: "userFirstName")
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        .onAppear {
            firstName = NSUbiquitousKeyValueStore.default.string(forKey: "userFirstName") ?? "user"
        }
    }
}
