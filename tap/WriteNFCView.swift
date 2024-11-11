//
//  WriteNFCView.swift
//  tap
//
//  Created by Aadi Katyal on 10/27/24.
//

import SwiftUI

struct WriteNFCView: View {
    @State private var urlToWrite: String = ""
    @State private var selectedScheme: String = "https"
    @State private var nfcManager = NFCManager()
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("url")) {
                    Picker("scheme", selection: $selectedScheme) {
                        Text("http").tag("http")
                        Text("https").tag("https")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("enter link", text: $urlToWrite)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    Button("write") {
                        let fullURL = "\(selectedScheme)://\(urlToWrite)"
                        if validateURL(fullURL) {
                            showError = false
                            nfcManager.beginWriteSession(urlString: fullURL) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            showError = true
                            errorMessage = "invalid url format"
                        }
                    }
                    .font(.body)
                    .foregroundColor(.blue)

                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationBarTitle("write to tap", displayMode: .inline)
        }
    }

    private func validateURL(_ urlString: String) -> Bool {
        let urlPattern = #"^(http|https)://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex?.firstMatch(in: urlString, options: [], range: range) != nil
    }
}
