//
//  AuthTokenManager.swift
//  DocAssist-ios
//
//  Created for authentication token management
//

import Foundation

/// Manages authentication tokens and provides token refresh functionality
public final class AuthTokenManager {
  
  public static let shared = AuthTokenManager()
  
  private var authToken: String?
  private var refreshToken: String?
  private var tokenRefreshInProgress = false
  private let tokenRefreshQueue = DispatchQueue(label: "com.docassist.tokenRefresh", attributes: .concurrent)
  
  private init() {}
  
  // MARK: - Token Management
  
  /// Sets the authentication tokens
  public func setTokens(authToken: String, refreshToken: String) {
    tokenRefreshQueue.async(flags: .barrier) { [weak self] in
      self?.authToken = authToken
      self?.refreshToken = refreshToken
    }
  }
  
  /// Gets the current auth token
  public func getAuthToken() -> String? {
    return tokenRefreshQueue.sync {
      return authToken
    }
  }
  
  /// Gets the current refresh token
  public func getRefreshToken() -> String? {
    return tokenRefreshQueue.sync {
      return refreshToken
    }
  }
  
  /// Clears all tokens
  public func clearTokens() {
    tokenRefreshQueue.async(flags: .barrier) { [weak self] in
      self?.authToken = nil
      self?.refreshToken = nil
    }
  }
  
  // MARK: - Token Refresh
  
  /// Refreshes the authentication token
  /// - Parameter completion: Completion handler with the new auth token or error
  public func refreshSession(completion: @escaping (Result<String, Error>) -> Void) {
    tokenRefreshQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else {
        completion(.failure(AuthError.unknown))
        return
      }
      
      // Prevent multiple simultaneous refresh attempts
      if self.tokenRefreshInProgress {
        // Wait for the ongoing refresh to complete
        self.tokenRefreshQueue.async {
          // Poll until refresh is complete
          var attempts = 0
          let maxAttempts = 50 // 5 seconds max wait
          Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            attempts += 1
            if !self.tokenRefreshInProgress || attempts >= maxAttempts {
              timer.invalidate()
              if let newToken = self.getAuthToken() {
                completion(.success(newToken))
              } else {
                completion(.failure(AuthError.tokenRefreshFailed))
              }
            }
          }
        }
        return
      }
      
      self.tokenRefreshInProgress = true
      
      guard let refreshToken = self.refreshToken else {
        self.tokenRefreshInProgress = false
        completion(.failure(AuthError.noRefreshToken))
        return
      }
      
      // Call the refresh session API
      self.performTokenRefresh(refreshToken: refreshToken) { [weak self] result in
        defer {
          self?.tokenRefreshInProgress = false
        }
        
        switch result {
        case .success(let newAuthToken):
          self?.authToken = newAuthToken
          completion(.success(newAuthToken))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }
  
  /// Performs the actual token refresh API call
  private func performTokenRefresh(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
    // TODO: Replace with your actual refresh token endpoint
    guard let url = URL(string: "YOUR_REFRESH_TOKEN_ENDPOINT") else {
      completion(.failure(AuthError.invalidURL))
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
      "refresh_token": refreshToken
    ]
    
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
      completion(.failure(error))
      return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        completion(.failure(AuthError.tokenRefreshFailed))
        return
      }
      
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let newToken = json["access_token"] as? String else {
        completion(.failure(AuthError.invalidResponse))
        return
      }
      
      completion(.success(newToken))
    }.resume()
  }
  
  /// Checks if the current session is active
  public func checkIfSessionIsActive(completion: @escaping (Bool) -> Void) {
    guard let authToken = getAuthToken() else {
      completion(false)
      return
    }
    
    // TODO: Replace with your actual session check endpoint
    guard let url = URL(string: "YOUR_SESSION_CHECK_ENDPOINT") else {
      completion(false)
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { _, response, _ in
      if let httpResponse = response as? HTTPURLResponse {
        completion((200...299).contains(httpResponse.statusCode))
      } else {
        completion(false)
      }
    }.resume()
  }
}

// MARK: - Auth Errors

public enum AuthError: LocalizedError {
  case unknown
  case noRefreshToken
  case noAuthToken
  case tokenRefreshFailed
  case invalidURL
  case invalidResponse
  case unauthorized
  
  public var errorDescription: String? {
    switch self {
    case .unknown:
      return "Unknown authentication error"
    case .noRefreshToken:
      return "No refresh token available"
    case .noAuthToken:
      return "No authentication token available"
    case .tokenRefreshFailed:
      return "Failed to refresh authentication token"
    case .invalidURL:
      return "Invalid URL for token refresh"
    case .invalidResponse:
      return "Invalid response from token refresh endpoint"
    case .unauthorized:
      return "Unauthorized - authentication required"
    }
  }
}
