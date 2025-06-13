//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation
import Network

public final class NetworkConfig {
  public var baseUrl: String = ""
  public var queryParams: [String: String] = [:]
  public var httpMethod: String = ""
  
  public static let shared = NetworkConfig()
  private init() {}
}

final class NetworkCall: NSObject, URLSessionTaskDelegate {
  
  private var session: URLSession?
  private var dataTask: URLSessionDataTask?
  private var streamDelegate: StreamDelegate?
  
  override init() {
    super.init()
  }
  
  func startStreamingPostRequest(query: String?, vault_files: [String]?, onStreamComplete: @Sendable @escaping () -> Void, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
    // Create the stream delegate first
    let streamDelegate = StreamDelegate(completion: completion, onStreamComplete: onStreamComplete)
    self.streamDelegate = streamDelegate
    
    guard var urlComponents = URLComponents(string: NetworkConfig.shared.baseUrl) else {
      fatalError("Invalid URL")
    }
    let queryItems = NetworkConfig.shared.queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
    urlComponents.queryItems = queryItems
    guard let url = urlComponents.url else {
      fatalError("Invalid URL")
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = NetworkConfig.shared.httpMethod
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
    
    var messageData: [String: Any] = ["role": "user"]
    
    if let text = query, !text.isEmpty {
      messageData["text"] = text
    }
    
    if let vaultFiles = vault_files, !vaultFiles.isEmpty {
      messageData["vault_files"] = vaultFiles
    }
    
    let jsonData: [String: Any] = [
      "messages": [messageData]
    ]
    
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: jsonData, options: [])
    } catch {
      completion(.failure(error))
      return
    }
    
    // Create a session with the delegate and retain it
    session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: .main)
    dataTask = session?.dataTask(with: request)
    dataTask?.resume()
  }
  
  func cancelStreaming() {
    dataTask?.cancel()
    dataTask = nil
    session?.invalidateAndCancel()
    session = nil
    streamDelegate = nil
    print("Streaming task canceled.")
  }
}


final class StreamDelegate: NSObject, URLSessionDataDelegate {
    private let completion: @Sendable (Result<String, Error>) -> Void
    private let onStreamComplete: @Sendable () -> Void
    private var buffer = Data()
    private var chunkCounter = 0

    init(
        completion: @escaping @Sendable (Result<String, Error>) -> Void,
        onStreamComplete: @escaping @Sendable () -> Void
    ) {
        self.completion = completion
        self.onStreamComplete = onStreamComplete
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        while true {
            if let range = buffer.range(of: Data("\n\n".utf8)) {
                let chunkData = buffer.subdata(in: 0..<range.lowerBound)
                buffer.removeSubrange(0..<range.upperBound)
                if let chunkString = String(data: chunkData, encoding: .utf8), !chunkString.isEmpty {
                    chunkCounter += 1
                    print("#BB chunkCounter \(chunkCounter) received")
                    completion(.success(chunkString))
                }
            } else {
                break
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? URLError, error.code != .cancelled {
            print("Streaming error: \(error.localizedDescription)")
            completion(.failure(error))
        } else if let error = error {
            print("Stream cancelled or other error: \(error.localizedDescription)")
        } else {
            print("Streaming complete successfully")
            // Emit any remaining data as a final chunk
            if !buffer.isEmpty, let finalString = String(data: buffer, encoding: .utf8) {
                completion(.success(finalString))
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.onStreamComplete()
        }
    }
}

@MainActor
class NetworkMonitor: ObservableObject {
  @Published var isConnected: Bool = true
  
  private var monitor: NWPathMonitor
  private let queue = DispatchQueue.global(qos: .background)
  
  init() {
    monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in
      DispatchQueue.main.async {
        self.isConnected = path.status == .satisfied
      }
    }
    monitor.start(queue: queue)
  }
  
  deinit {
    monitor.cancel()
  }
}
