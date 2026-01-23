//
//  AuthInterceptor.swift
//  DocAssist-ios
//
//  Created for request authentication interceptor
//

import Foundation

/// Protocol for request interception
public protocol RequestInterceptor {
  func intercept(_ request: inout URLRequest) throws
}

/// Authentication interceptor that adds auth headers to requests
public final class AuthInterceptor: RequestInterceptor {
  
  private let tokenManager: AuthTokenManager
  private let shouldRefreshOn401: Bool
  
  public init(tokenManager: AuthTokenManager = .shared, shouldRefreshOn401: Bool = true) {
    self.tokenManager = tokenManager
    self.shouldRefreshOn401 = shouldRefreshOn401
  }
  
  /// Intercepts and modifies the request to add authentication headers
  public func intercept(_ request: inout URLRequest) throws {
    // Skip authentication for certain endpoints (like login, refresh token)
    if shouldSkipAuthentication(for: request) {
      return
    }
    
    // Get the current auth token
    guard let authToken = tokenManager.getAuthToken() else {
      throw AuthError.noAuthToken
    }
    
    // Add Authorization header
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
  }
  
  /// Checks if authentication should be skipped for this request
  private func shouldSkipAuthentication(for request: URLRequest) -> Bool {
    guard let url = request.url?.absoluteString else { return false }
    
    // Add endpoints that don't require authentication
    let skipAuthEndpoints = [
      "login",
      "refresh",
      "register"
    ]
    
    return skipAuthEndpoints.contains { url.localizedCaseInsensitiveContains($0) }
  }
  
  /// Handles 401 unauthorized response by attempting token refresh
  public func handleUnauthorized(
    request: URLRequest,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    guard shouldRefreshOn401 else {
      completion(.failure(AuthError.unauthorized))
      return
    }
    
    tokenManager.refreshSession { [weak self] result in
      switch result {
      case .success:
        // Retry the original request with new token
        var retryRequest = request
        do {
          try self?.intercept(&retryRequest)
          completion(.success(retryRequest))
        } catch {
          completion(.failure(error))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

