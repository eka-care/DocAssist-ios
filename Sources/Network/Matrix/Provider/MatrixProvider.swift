//
//  MatrixProvider.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

protocol MatrixProvider {
  var networkService: Networking { get }
  
  /// Create a new session
  /// - Parameters:
  ///   - requestModel: AuthSessionRequestModel containing user ID
  ///   - completion: Completion callback with AuthSessionResponseModel or Error
  func createSession(
    requestModel: AuthSessionRequestModel,
    _ completion: @escaping (Result<AuthSessionResponseModel, Error>, Int?) -> Void
  )
}

extension MatrixProvider {
  func createSession(
    requestModel: AuthSessionRequestModel,
    _ completion: @escaping (Result<AuthSessionResponseModel, Error>, Int?) -> Void
  ) {
    networkService.execute(MatrixEndpoint.createSession(requestModel: requestModel), completion: completion)
  }
}
