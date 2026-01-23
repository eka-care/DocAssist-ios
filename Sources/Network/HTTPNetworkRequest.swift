//
//  HTTPNetworkRequest.swift
//  DocAssist-ios
//
//  Created for HTTP network requests with authentication interceptor
//

import Foundation

/// HTTP Network Request utility with authentication interceptor support
public final class HTTPNetworkRequest {
  
  private let interceptor: RequestInterceptor?
  private let session: URLSession
  
  public init(interceptor: RequestInterceptor? = AuthInterceptor(), session: URLSession = .shared) {
    self.interceptor = interceptor
    self.session = session
  }
  
  // MARK: - Generic HTTP Request
  
  /// Performs an HTTP request with authentication interceptor
  /// - Parameters:
  ///   - url: The URL to request
  ///   - method: HTTP method (GET, POST, PUT, DELETE, etc.)
  ///   - headers: Additional headers to include
  ///   - body: Request body data
  ///   - completion: Completion handler with result
  public func request(
    url: URL,
    method: String = "GET",
    headers: [String: String]? = nil,
    body: Data? = nil,
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    var request = URLRequest(url: url)
    request.httpMethod = method
    
    // Add custom headers
    headers?.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }
    
    // Add body if provided
    if let body = body {
      request.httpBody = body
    }
    
    // Apply interceptor
    do {
      try interceptor?.intercept(&request)
    } catch {
      completion(.failure(error))
      return
    }
    
    // Perform the request
    session.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(HTTPError.invalidResponse))
        return
      }
      
      // Handle 401 Unauthorized
      if httpResponse.statusCode == 401,
         let authInterceptor = self?.interceptor as? AuthInterceptor {
        authInterceptor.handleUnauthorized(request: request) { result in
          switch result {
          case .success(let retryRequest):
            // Retry the request with new token
            self?.session.dataTask(with: retryRequest) { data, response, error in
              if let error = error {
                completion(.failure(error))
                return
              }
              
              guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(HTTPError.invalidResponse))
                return
              }
              
              let httpResponseObj = HTTPResponse(
                data: data,
                response: httpResponse,
                statusCode: httpResponse.statusCode
              )
              completion(.success(httpResponseObj))
            }.resume()
          case .failure(let error):
            completion(.failure(error))
          }
        }
        return
      }
      
      let httpResponseObj = HTTPResponse(
        data: data,
        response: httpResponse,
        statusCode: httpResponse.statusCode
      )
      completion(.success(httpResponseObj))
    }.resume()
  }
  
  // MARK: - Convenience Methods
  
  /// GET request
  public func get(
    url: URL,
    headers: [String: String]? = nil,
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    request(url: url, method: "GET", headers: headers, completion: completion)
  }
  
  /// POST request
  public func post(
    url: URL,
    headers: [String: String]? = nil,
    body: Data? = nil,
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    request(url: url, method: "POST", headers: headers, body: body, completion: completion)
  }
  
  /// PUT request
  public func put(
    url: URL,
    headers: [String: String]? = nil,
    body: Data? = nil,
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    request(url: url, method: "PUT", headers: headers, body: body, completion: completion)
  }
  
  /// DELETE request
  public func delete(
    url: URL,
    headers: [String: String]? = nil,
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    request(url: url, method: "DELETE", headers: headers, completion: completion)
  }
}

// MARK: - HTTP Response Model

public struct HTTPResponse {
  public let data: Data?
  public let response: HTTPURLResponse
  public let statusCode: Int
  
  /// Decodes the response data to a Codable type
  public func decode<T: Decodable>(_ type: T.Type) throws -> T {
    guard let data = data else {
      throw HTTPError.noData
    }
    return try JSONDecoder().decode(type, from: data)
  }
  
  /// Returns the response as a string
  public func string() -> String? {
    guard let data = data else { return nil }
    return String(data: data, encoding: .utf8)
  }
  
  /// Returns the response as a dictionary
  public func dictionary() -> [String: Any]? {
    guard let data = data else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  }
}

// MARK: - HTTP Errors

public enum HTTPError: LocalizedError {
  case invalidResponse
  case noData
  case decodingError
  
  public var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid HTTP response"
    case .noData:
      return "No data in response"
    case .decodingError:
      return "Failed to decode response"
    }
  }
}

// MARK: - API Methods

extension HTTPNetworkRequest {
  
  /// Checks if the current session is active
  public func checkIfSessionIsActive(completion: @escaping (Result<Bool, Error>) -> Void) {
    // TODO: Replace with your actual session check endpoint
    guard let url = URL(string: "YOUR_SESSION_CHECK_ENDPOINT") else {
      completion(.failure(HTTPError.invalidResponse))
      return
    }
    
    get(url: url) { result in
      switch result {
      case .success(let response):
        completion(.success((200...299).contains(response.statusCode)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  /// Refreshes the authentication session
  public func refreshSession(completion: @escaping (Result<String, Error>) -> Void) {
    AuthTokenManager.shared.refreshSession(completion: completion)
  }
  
  /// Creates a new session
  public func createSession(
    parameters: [String: Any],
    completion: @escaping (Result<HTTPResponse, Error>) -> Void
  ) {
    // TODO: Replace with your actual create session endpoint
    guard let url = URL(string: "YOUR_CREATE_SESSION_ENDPOINT") else {
      completion(.failure(HTTPError.invalidResponse))
      return
    }
    
    let body: Data?
    do {
      body = try JSONSerialization.data(withJSONObject: parameters)
    } catch {
      completion(.failure(error))
      return
    }
    
    post(url: url, body: body, completion: completion)
  }
}
