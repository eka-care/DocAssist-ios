//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation

public final class NwConfig {
  public var baseUrl: String = ""
  public var queryParams: [String: String] = [:]
  public var httpMethod: String = ""
  
  @MainActor public static let shared = NwConfig()
  private init() {}
}

final class NetworkCall: NSObject, URLSessionTaskDelegate {
  
  @MainActor func startStreamingPostRequest(query: String, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
    
    let streamDelegate = StreamDelegate(completion: completion)
    
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
<<<<<<< HEAD
    print("#BB request \(request)")
=======
>>>>>>> 0c4f791 (Fixed Bugs and working code)
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
  init(completion: @escaping  @Sendable (Result<String, Error>) -> Void) {
    self.completion = completion
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    let receivedString = String(data: data, encoding: .utf8) ?? ""
    print("#BB \(receivedString)")
    completion(.success(receivedString))
    
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      print("Streaming error: \(error.localizedDescription)")
    } else {
      print("Streaming complete")
    }
  }
}
<<<<<<< HEAD
=======



>>>>>>> 0c4f791 (Fixed Bugs and working code)
