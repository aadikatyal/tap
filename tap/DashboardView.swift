import SwiftUI
import CoreNFC

struct DashboardView: View {
    @Binding var firstName: String
    @Binding var isAuthenticated: Bool
    @State private var showSettings = false
    @State private var showLogOutConfirmation = false
    @State private var nfcManager = NFCManager()
    @State private var scannedMessages: [NFCNDEFMessage] = []

    var body: some View {
        VStack {
            List(scannedMessages, id: \.self) { message in
                ForEach(message.records, id: \.self) { record in
                    Text(String(decoding: record.payload, as: UTF8.self))
                }
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                showSettings.toggle()
            }) {
                Image(systemName: "gear")
            },
            trailing: Button("scan") {
                nfcManager.onNFCResult = handleNFCResult
                nfcManager.beginSession()
            }
        )
        .navigationTitle("welcome \(firstName.lowercased())")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            SettingsView(firstName: $firstName, isAuthenticated: $isAuthenticated, showLogOutConfirmation: $showLogOutConfirmation)
        }
    }
    
    func handleNFCResult(result: Result<[NFCNDEFMessage], Error>) {
        switch result {
        case .success(let messages):
            scannedMessages = messages
        case .failure(let error):
            print("NFC scanning failed:", error)
        }
    }
}

struct SettingsView: View {
    @Binding var firstName: String
    @Binding var isAuthenticated: Bool
    @State private var showNameEdit = false
    @Binding var showLogOutConfirmation: Bool

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
                    Button("my saved tags") {
                        // to do
                    }
                }
                
                Section {
                    Button("log out") {
                        showLogOutConfirmation = true
                    }
                    .alert("are you sure you want to log out?", isPresented: $showLogOutConfirmation) {
                        Button("cancel", role: .cancel) {}
                        Button("log out", role: .destructive) {
                            isAuthenticated = false
                            UserDefaults.standard.removeObject(forKey: "userID")
                        }
                    }
                }
            }
            .navigationTitle("settings")
            .sheet(isPresented: $showNameEdit) {
                NameEditView(firstName: $firstName)
            }
        }
    }
}

struct NameEditView: View {
    @Binding var firstName: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("enter your name", text: $firstName)
            }
            .navigationBarTitle("edit name", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                UserDefaults.standard.set(firstName, forKey: "userFirstName")
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
