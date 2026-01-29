//
//  MatrixProvider.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

protocol MatrixProvider {
  var networkService: Networking { get }

  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  )
}

extension MatrixProvider {
  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(AuthEndpoint.tokenRefresh(refreshRequest: refreshRequest), completion: completion)
  }
}
