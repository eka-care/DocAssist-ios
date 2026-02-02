//
//  AuthProvider.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

protocol AuthProvider {
  var networkService: Networking { get }
  
  /// Use this endpoint with the refresh token to get a new session token
  /// - Parameters:
  ///   - refreshRequest: RefreshRequest
  ///   - completion: Completion callback
  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  )
}

extension AuthProvider {
  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(AuthEndpoint.tokenRefresh(refreshRequest: refreshRequest), completion: completion)
  }
}