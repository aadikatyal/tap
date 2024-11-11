import SwiftUI

struct SavedTagsView: View {
    @Binding var savedMessages: [String]

    var body: some View {
        NavigationView {
            List {
                if savedMessages.isEmpty {
                    // display centered message if no saved messages
                    VStack {
                        Text("no messages saved")
                            .foregroundColor(.gray)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Section(header: Text("urls")) {
                        ForEach(savedMessages, id: \.self) { message in
                            // sanitize and create a valid url
                            let sanitizedMessage = sanitizeURLString(message)
                            
                            if let url = createValidURL(from: sanitizedMessage) {
                                let displayText = removeHttpsPrefix(from: url.absoluteString) // display without https://
                                Link(displayText, destination: url)
                                    .foregroundColor(.blue)
                                    .contextMenu {
                                        Button(action: {
                                            UIPasteboard.general.string = sanitizedMessage
                                        }) {
                                            Text("copy url")
                                            Image(systemName: "doc.on.doc")
                                        }
                                    }
                            } else {
                                Text(message)
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
                        }
                        .onDelete(perform: deleteMessage)
                    }
                }
            }
            .navigationTitle("saved messages")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // function to delete a message
    private func deleteMessage(at offsets: IndexSet) {
        savedMessages.remove(atOffsets: offsets)
        NSUbiquitousKeyValueStore.default.set(savedMessages, forKey: "savedLinks")
    }
    
    // function to create a valid url by adding https:// if missing
    private func createValidURL(from urlString: String) -> URL? {
        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStr.hasPrefix("http://") && !urlStr.hasPrefix("https://") {
            urlStr = "https://\(urlStr)"
        }
        if let url = URL(string: urlStr) {
            print("generated url: \(url)") // debug: verify url generation
            return url
        }
        print("invalid url after sanitizing: \(urlString)")
        return nil
    }
    
    // function to remove https:// prefix for display
    private func removeHttpsPrefix(from urlString: String) -> String {
        if urlString.hasPrefix("https://") {
            return String(urlString.dropFirst(8)) // remove "https://"
        } else if urlString.hasPrefix("http://") {
            return String(urlString.dropFirst(7)) // remove "http://"
        }
        return urlString
    }
    
    // function to sanitize the url string by removing non-printable characters
    private func sanitizeURLString(_ urlString: String) -> String {
        let pattern = "[^\u{20}-\u{7E}]" // matches non-printable ascii characters
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex?.stringByReplacingMatches(in: urlString, options: [], range: range, withTemplate: "") ?? urlString
    }
}
