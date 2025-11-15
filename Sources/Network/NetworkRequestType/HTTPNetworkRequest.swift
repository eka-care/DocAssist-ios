//
//  HTTPNetworkRequest.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//
import Foundation

enum HttpMethod: String {
  case get , put , post , delete, patch
}

struct HTTPNetworkRequest: NetworkRequest {
  let url: URL
  let method: HttpMethod
  let headers: [String: String]?
  let body: Data?
  
  func execute(completion: @escaping (Result<Data, Error>) -> Void) {
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    request.httpBody = body
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
      } else if let data = data {
        completion(.success(data))
      }
    }
    task.resume()
  }
}

