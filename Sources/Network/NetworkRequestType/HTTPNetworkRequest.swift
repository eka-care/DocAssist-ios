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

  
  func execute(completion: @escaping (Result<Data, ApiError>) -> Void) {
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    request.httpBody = body
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        DispatchQueue.main.async { completion(.failure(.networkError(error))) }
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse, let data = data else {
        DispatchQueue.main.async { completion(.failure(.unknownError)) }
        return
      }
      
      if (200...299).contains(httpResponse.statusCode) {
        DispatchQueue.main.async { completion(.success(data)) }
      } else {
        // Pass the status code AND the raw data to the error handler
        DispatchQueue.main.async { completion(.failure(.serverError(statusCode: httpResponse.statusCode, data: data))) }
      }
    }
    task.resume()
  }
}

