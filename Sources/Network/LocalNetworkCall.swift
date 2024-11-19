//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation

final class ChatNetworkingService: NSObject, URLSessionTaskDelegate {
  
//    private let baseUrl: String = "https://lucid-ws.eka.care/doc_chat/v1/stream_chat"
//  
//    func startStreamingPostRequest(sessionId: String, query: String, completion: @escaping (Result<String, Error>) -> Void) {
//      let streamDelegate = StreamDelegate(completion: completion)
//        guard let url = URL(string: "\(baseUrl)?d_oid=161467756044203&d_hash=6d36c3ca25abe7d9f34b81727f03d719&pt_oid=161857870651607&session_id=\(sessionId)") else {
//            fatalError("Invalid URL")
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
//        
//        let jsonData: [String: Any] = [
//            "messages": [
//                ["role": "user", "text": query]
//            ]
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: jsonData, options: [])
//        } catch {
//            completion(.failure(error))
//            return
//        }
//        
//      let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: nil)
//      
//      let dataTask = session.dataTask(with: request)
//      
//      dataTask.delegate = self
//      dataTask.resume()
//    }

  func startStreamingPostRequest(networkConfig: NetworkConfiguration, query: String, completion: @Sendable @escaping (Result<String, Error>) -> Void) {
      let streamDelegate = StreamDelegate(completion: completion)
    
    guard var urlComponents = URLComponents(string: networkConfig.baseUrl) else {
      fatalError("Invalid URL")
    }
    let queryItems = networkConfig.queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
    urlComponents.queryItems = queryItems
    guard let url = urlComponents.url else {
      fatalError("Invalid URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
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
      // Fallback on earlier versions
    }
  dataTask.resume()
}

}

final class StreamDelegate: NSObject, @preconcurrency URLSessionDataDelegate {
  
  private let completion: @Sendable (Result<String, Error>) -> Void
  init(completion: @escaping  @Sendable (Result<String, Error>) -> Void) {
      self.completion = completion
  }
  
  @MainActor func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    let receivedString = String(data: data, encoding: .utf8) ?? ""
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

struct NetworkConfiguration {
  let baseUrl: String
  var queryParams: [String: String] = [:]
  var jsonBody: [String: Any]?
  let httpMethod: String
}
