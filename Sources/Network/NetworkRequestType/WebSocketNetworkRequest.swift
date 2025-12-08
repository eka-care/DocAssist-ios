//
//  WebSocketNetworkRequest.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//
import Foundation

final class WebSocketNetworkRequest: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    var onMessageDecoded: ((WebSocketModel) -> Void)?
  
  var operationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .userInitiated
    return queue
   }()

    let url: URL

    init(url: URL) {
        self.url = url
        super.init()
    }

    // 1️⃣ Establish the connection
    func connect(completion: @escaping (Bool) -> Void) {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        print("✅ WebSocket connected to \(url)")
        completion(true)

        // start listening as soon as connected
        listenForMessages()
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
        
        // Keep listening
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

    // 5️⃣ Optional: delegate callbacks for debugging
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed with code: \(closeCode)")
        isConnected = false
    }
}
