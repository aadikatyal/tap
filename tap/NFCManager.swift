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

    func beginSession() {
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "tap your tag ᯤ"
        session?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.onNFCResult?(.failure(error))
        }
        self.session = nil
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.onNFCResult?(.success(messages))
            session.invalidate()
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session active")
    }
}
