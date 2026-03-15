//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation
import Network
import Alamofire

public final class NetworkConfig {
  public var baseUrl: String = ""
  public var queryParams: [String: String] = [:]
  public var httpMethod: String = ""
  
  public static let shared = NetworkConfig()
  private init() {}
}

final class NetworkCall: NSObject, URLSessionTaskDelegate {
  
  private var dataTask: URLSessionDataTask?
  
  override init() {
    super.init()
    dataTask?.delegate = self
  }
  
  func startStreamingPostRequest(query: String?, vault_files: [String]?, onStreamComplete: @Sendable @escaping () -> Void, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
    let streamDelegate = StreamDelegate(completion: completion, onStreamComplete: onStreamComplete)
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
    
    let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: .main)
    dataTask = session.dataTask(with: request)
    dataTask?.resume()
  }
  
  func cancelStreaming() {
      dataTask?.cancel()
      dataTask = nil
      print("Streaming task canceled.")
    }
}


final class StreamDelegate: NSObject, URLSessionDataDelegate {
  
  // MARK: - Properties
  
  private let completion: @Sendable (Result<String, Error>) -> Void
  private let onStreamComplete: @Sendable () -> Void
  private var receivedData = Data()
  
  // MARK: - Init
  
  init(
    completion: @escaping @Sendable (Result<String, Error>) -> Void,
    onStreamComplete: @escaping @Sendable () -> Void
  ) {
    self.completion = completion
    self.onStreamComplete = onStreamComplete
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    receivedData.append(data)
    if let receivedString = String(data: receivedData, encoding: .utf8) {
      completion(.success(receivedString))
    }
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      print("Streaming error: \(error.localizedDescription)")
    } else {
      print("Streaming complete")
    }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      onStreamComplete()
    }
  }
}


import Foundation
import Network

enum ApiError: Error {
    case networkError(Error)
    case serverError(statusCode: Int, data: Data)
    case unknownError
}

protocol NetworkRequest {
    func execute(completion: @escaping (Result<Data, ApiError>) -> Void)
}

final class NetworkManager {
  static let shared = NetworkManager()
  private init() {}
  
  func perform(request: NetworkRequest, completion: @escaping (Result<Data, ApiError>) -> Void) {
    request.execute(completion: completion)
  }
}

protocol RequestProvider {
  var urlRequest: DataRequest { get }
}
