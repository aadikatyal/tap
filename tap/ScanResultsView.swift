import SwiftUI
import CoreNFC

struct ScanResultsView: View {
    @Binding var scannedMessages: [NFCNDEFMessage]
    var onSave: (String) -> Void // closure to save message
    @State private var showAlert = false // state for alert
    @Environment(\.presentationMode) var presentationMode // to close the view

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("scan results")) {
                    ForEach(scannedMessages, id: \.self) { message in
                        let parsedMessage = messageToString(message)
                        let sanitizedMessage = sanitizeURLString(parsedMessage)
                        
                        // Check if the sanitized message is a valid URL and display it as a clickable link
                        if let url = createValidURL(from: sanitizedMessage) {
                            Link(removeHttpsPrefix(from: url.absoluteString), destination: url)
                                .font(.body)
                                .foregroundColor(.blue)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = sanitizedMessage
                                    }) {
                                        Text("copy text")
                                        Image(systemName: "doc.on.doc")
                                    }
                                }
                        } else {
                            Text(parsedMessage)
                                .font(.body)
                                .foregroundColor(.primary)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = sanitizedMessage
                                    }) {
                                        Text("copy text")
                                        Image(systemName: "doc.on.doc")
                                    }
                                }
                        }
                        
                        // Separate "save" button below the message
                        Button("save") {
                            onSave(sanitizedMessage) // save the message when clicked
                            showAlert = true // show alert
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationBarTitle("scan results", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("saved"),
                    message: Text("message saved successfully"),
                    dismissButton: .default(Text("close")) {
                        presentationMode.wrappedValue.dismiss() // close the view after alert
                    }
                )
            }
        }
    }
    
    // helper function to convert NFC message to string
    private func messageToString(_ message: NFCNDEFMessage) -> String {
        return message.records.compactMap { String(data: $0.payload, encoding: .utf8) }
            .joined(separator: ", ")
    }
    
    // function to sanitize the URL string by removing non-printable characters
    private func sanitizeURLString(_ urlString: String) -> String {
        let pattern = "[^\u{20}-\u{7E}]" // Matches non-printable ASCII characters
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex?.stringByReplacingMatches(in: urlString, options: [], range: range, withTemplate: "") ?? urlString
    }
    
    // function to create a valid URL by adding https:// if missing
    private func createValidURL(from urlString: String) -> URL? {
        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
            urlStr = "https://\(urlStr)"
        }
        return URL(string: urlStr)
    }
    
    // function to remove https:// prefix for display
    private func removeHttpsPrefix(from urlString: String) -> String {
        if urlString.hasPrefix("https://") {
            return String(urlString.dropFirst(8)) // Remove "https://"
        } else if urlString.hasPrefix("http://") {
            return String(urlString.dropFirst(7)) // Remove "http://"
        }
        return urlString
    }
}
