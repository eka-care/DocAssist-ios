//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation
import Network

public final class NwConfig {
  public var baseUrl: String = ""
  public var queryParams: [String: String] = [:]
  public var httpMethod: String = ""
  
  @MainActor public static let shared = NwConfig()
  private init() {}
}

final class NetworkCall: NSObject, URLSessionTaskDelegate {
  
  @MainActor func startStreamingPostRequest(query: String, onStreamComplete: @Sendable @escaping () -> Void, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
    
    let streamDelegate = StreamDelegate(completion: completion, onStreamComplete: onStreamComplete)
    
    guard var urlComponents = URLComponents(string: NwConfig.shared.baseUrl) else {
      fatalError("Invalid URL")
    }
    let queryItems = NwConfig.shared.queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
    urlComponents.queryItems = queryItems
    guard let url = urlComponents.url else {
      fatalError("Invalid URL")
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = NwConfig.shared.httpMethod
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
    
    let jsonData: [String: Any] = [
      "messages": [
        ["role": "user", "text": query]
      ]
    ]
    
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: jsonData, options: [])
    } catch {
      completion(.failure(error))
      return
    }
    
    let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: nil)
    let dataTask = session.dataTask(with: request)
    
    if #available(iOS 15.0, *) {
      dataTask.delegate = self
    } else {
    }
    dataTask.resume()
  }
}


final class StreamDelegate: NSObject, URLSessionDataDelegate {
  
  private let completion: @Sendable (Result<String, Error>) -> Void
  private let onStreamComplete: @Sendable () -> Void
  init(
         completion: @escaping @Sendable (Result<String, Error>) -> Void,
         onStreamComplete: @escaping @Sendable () -> Void
     ) {
         self.completion = completion
         self.onStreamComplete = onStreamComplete
     }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    let receivedString = String(data: data, encoding: .utf8) ?? ""
    completion(.success(receivedString))
    
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      print("Streaming error: \(error.localizedDescription)")
    } else {
      print("Streaming complete")
    }
    onStreamComplete()
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
