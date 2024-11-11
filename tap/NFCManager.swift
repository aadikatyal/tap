//
//  NFCManager.swift
//  tap
//
//  Created by Aadi Katyal on 10/14/24.
//

import Foundation
import CoreNFC

class NFCManager: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?
    var onNFCResult: ((Result<[NFCNDEFMessage], Error>) -> Void)?
    private var messageToWrite: NFCNDEFMessage?
    private var writeCompletion: (() -> Void)?  // completion closure for successful writes

    // initiates a read session
    func beginSession() {
        messageToWrite = nil  // ensures this is a read-only session
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false) // keep session active
        session?.alertMessage = "tap to read ᯤ"
        session?.begin()
    }

    // initiates a write session with the provided URL
    func beginWriteSession(urlString: String, completion: @escaping () -> Void) {
        // store the completion closure
        writeCompletion = completion

        // validate the url and create the nfc payload
        guard let url = URL(string: urlString), url.scheme != nil else {
            print("invalid url format")
            return
        }
        
        guard let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
            print("failed to create payload")
            return
        }
        
        // set the message to write and start a write session
        messageToWrite = NFCNDEFMessage(records: [payload])
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false) // keep session active
        session?.alertMessage = "tap to write ᯤ"
        session?.begin()
    }

    // handle session invalidation errors
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Only report error if session wasn’t canceled by the user
        if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            print("nfc session closed")
            return // do not report as failure
        }
        DispatchQueue.main.async {
            self.onNFCResult?(.failure(error))
        }
        self.session = nil
    }

    // handle detection of ndef messages (reading)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.onNFCResult?(.success(messages))
        }
        session.invalidate() // close session only after read success
    }

    // handles detection of nfc tags (writing)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "no tag detected")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "connection failed: \(error.localizedDescription)")
                return
            }

            // check for read or write based on messageToWrite
            if self.messageToWrite == nil {
                // Read-only session
                tag.readNDEF { message, error in
                    if let error = error {
                        session.invalidate(errorMessage: "failed to read: \(error.localizedDescription)")
                    } else if let message = message {
                        DispatchQueue.main.async {
                            self.onNFCResult?(.success([message]))
                        }
                        session.invalidate() // Close session only after successful read
                    }
                }
            } else {
                // write session
                tag.queryNDEFStatus { status, capacity, error in
                    self.handleTagWriteStatus(tag: tag, status: status, capacity: capacity, session: session, error: error)
                }
            }
        }
    }
    
    private func handleTagWriteStatus(tag: NFCNDEFTag, status: NFCNDEFStatus, capacity: Int, session: NFCNDEFReaderSession, error: Error?) {
        if let error = error {
            session.invalidate(errorMessage: "failed to query NDEF status: \(error.localizedDescription)")
            return
        }
        
        switch status {
        case .notSupported:
            session.invalidate(errorMessage: "tag not supported")
        case .readOnly:
            session.invalidate(errorMessage: "tag is read-only")
        case .readWrite:
            guard let message = self.messageToWrite else {
                session.invalidate(errorMessage: "no message to write")
                return
            }
            if message.length > capacity {
                session.invalidate(errorMessage: "message too large for tag")
                return
            }
            
            // write the ndef message
            tag.writeNDEF(message) { error in
                if let error = error {
                    session.invalidate(errorMessage: "write failed: \(error.localizedDescription)")
                } else {
                    session.alertMessage = "successfully wrote url ᯤ"
                    session.invalidate()
                    
                    // call completion closure on successful write
                    self.writeCompletion?()
                    self.writeCompletion = nil  // clear after use
                }
            }
        @unknown default:
            session.invalidate(errorMessage: "unknown tag status")
        }
    }

    // handles session activation
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("nfc session active")
    }
}
