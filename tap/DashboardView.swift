import SwiftUI
import CoreNFC
import CloudKit

struct DashboardView: View {
    @Binding var firstName: String
    @Binding var isAuthenticated: Bool
    @State private var showSettings = false
    @State private var showLogOutConfirmation = false
    @State private var showScanResults = false
    @State private var showWriteModal = false
    @State private var showSavedTags = false
    @State private var nfcManager = NFCManager()
    @State private var scannedMessages: [NFCNDEFMessage] = []
    @State private var savedMessages: [String] = []

    var body: some View {
        NavigationView { // Wrapping the entire content with NavigationView
            List {
                Section {
                    Button(action: {
                        showSavedTags.toggle()
                    }) {
                        HStack {
                            Text("saved messages")
                            Spacer()
                            Image(systemName: "bookmark.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("welcome \(firstName.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                },
                trailing: Menu {
                    Button("read", action: startReading)
                    Button("write") {
                        showWriteModal = true
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $showWriteModal) {
                    WriteNFCView()
                }
                .sheet(isPresented: $showScanResults) {
                    ScanResultsView(scannedMessages: $scannedMessages, onSave: saveScannedMessage)
                }
            )
            .sheet(isPresented: $showSettings) {
                SettingsView(firstName: $firstName, isAuthenticated: $isAuthenticated)
            }
            .sheet(isPresented: $showSavedTags) {
                SavedTagsView(savedMessages: $savedMessages)
            }
            .onAppear {
                loadSavedMessagesFromCloud()
                firstName = NSUbiquitousKeyValueStore.default.string(forKey: "userFirstName") ?? "user"
            }
            .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
                loadSavedMessagesFromCloud()
                firstName = NSUbiquitousKeyValueStore.default.string(forKey: "userFirstName") ?? firstName
            }
        }
    }
    
    // function to start NFC reading session
    func startReading() {
        nfcManager.onNFCResult = { result in
            handleNFCResult(result: result)
        }
        nfcManager.beginSession()
    }
    
    // function to handle nfc results
    func handleNFCResult(result: Result<[NFCNDEFMessage], Error>) {
        showScanResults = false
        switch result {
        case .success(let messages):
            scannedMessages = messages
            DispatchQueue.main.async {
                showScanResults = true
            }
        case .failure(let error):
            print("nfc scanning failed:", error)
        }
    }
    
    // save scanned message to iCloud Key-Value storage
    func saveScannedMessage(_ message: String) {
        let formattedMessage = ensureHttpsPrefix(for: message)
        savedMessages.append(formattedMessage)
        NSUbiquitousKeyValueStore.default.set(savedMessages, forKey: "savedLinks")
    }
    
    // load saved messages from iCloud Key-Value storage
    func loadSavedMessagesFromCloud() {
        if let loadedMessages = NSUbiquitousKeyValueStore.default.array(forKey: "savedLinks") as? [String] {
            savedMessages = loadedMessages
        }
    }
    
    // Helper function to add "https://" prefix if missing
    private func ensureHttpsPrefix(for message: String) -> String {
        return message.hasPrefix("http") ? message : "https://\(message)"
    }
}
