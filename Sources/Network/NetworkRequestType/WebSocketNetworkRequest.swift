//
//  WebSocketNetworkRequest.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//
import Foundation
import UIKit

final class WebSocketNetworkRequest: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var connectCompletion: ((Bool) -> Void)?
    var onMessageDecoded: ((WebSocketModel) -> Void)?
  
  var operationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .userInitiated
    return queue
   }()

    let url: URL
    private let headers: [String: String]

    init(url: URL, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
        super.init()
    }

    // 1️⃣ Establish the connection
    func connect(completion: @escaping (Bool) -> Void) {
        self.connectCompletion = completion
        session = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)

        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()
        print("⏳ WebSocket connecting to \(url)")
    }

    // 2️⃣ Send messages
    func send(message: String) {
        guard isConnected else {
            print("❌ Socket not connected. Cannot send message.")
            return
        }

        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            } else {
                print("📤 Sent message: \(message)")
            }
        }
    }

    // 3️⃣ Listen for messages continuously
  private func listenForMessages() {
    guard isConnected else { return }
    
    webSocketTask?.receive { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        print("❌ WebSocket receive error: \(error.localizedDescription)")
        self.isConnected = false
        
      case .success(let message):
        switch message {
        case .string(let text):
          if let data = text.data(using: .utf8) {
            do {
              let decoded = try JSONDecoder().decode(WebSocketModel.self, from: data)
              onMessageDecoded?(decoded)
            } catch {
              print("⚠️ Failed to decode WebSocketModel: \(error)")
            }
          }
          
        case .data(let data):
          print("📥 Received binary data: \(data.count) bytes")
          
        @unknown default:
          break
        }
        
        self.listenForMessages()
      }
    }
  }

    // 4️⃣ Disconnect cleanly
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
        print("🔌 WebSocket disconnected.")
    }

    // 5️⃣ Delegate: connection opened
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected to \(url)")
        isConnected = true
        listenForMessages()
        connectCompletion?(true)
        connectCompletion = nil
    }

    // 6️⃣ Delegate: connection closed
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed with code: \(closeCode)")
        isConnected = false
    }

    // 7️⃣ Delegate: connection failed at transport level
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ WebSocket connection error: \(error.localizedDescription)")
            isConnected = false
            connectCompletion?(false)
            connectCompletion = nil
        }
    }
}
