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
    private(set) var isConnected = false
    var onMessageDecoded: ((WebSocketModel) -> Void)?
    private var openContinuation: CheckedContinuation<Bool, Never>?

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

    // 1️⃣ Establish the connection — suspends until handshake completes
    func connect() async -> Bool {
        return await withCheckedContinuation { continuation in
            openContinuation = continuation

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 300

            session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)

            var request = URLRequest(url: url)
            request.timeoutInterval = 30

            webSocketTask = session?.webSocketTask(with: request)
            webSocketTask?.resume()
        }
    }

    // Delegate: called once the WebSocket handshake is complete
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        print("✅ WebSocket connected to \(url)")
        listenForMessages()
        openContinuation?.resume(returning: true)
        openContinuation = nil
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
                            self.onMessageDecoded?(decoded)
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
        openContinuation?.resume(returning: false)
        openContinuation = nil
        print("🔌 WebSocket disconnected.")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
        print("🔴 WebSocket closed — code: \(closeCode.rawValue), reason: \(reasonString)")
        isConnected = false
        openContinuation?.resume(returning: false)
        openContinuation = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("🔴 URLSession task completed with error: \(error)")
            isConnected = false
            openContinuation?.resume(returning: false)
            openContinuation = nil
        }
    }
}
