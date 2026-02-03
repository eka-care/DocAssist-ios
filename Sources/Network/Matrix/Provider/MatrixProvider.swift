//
//  MatrixProvider.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

protocol MatrixProvider {
  var networkService: Networking { get }
  
  func createSession(
    requestModel: AuthSessionRequestModel,
    _ completion: @escaping (Result<AuthSessionResponseModel, Error>, Int?) -> Void
  )
  
  func checkSessionStatus(
    sessionId: String,
    _ completion: @escaping (Result<SessionValidResponseModel, Error>, Int?) -> Void
  )
  
  func refreshSession(
    sessionId: String,
    _ completion: @escaping (Result<SessionValidResponseModel, Error>, Int?) -> Void
  )
}

extension MatrixProvider {
  func createSession(
    requestModel: AuthSessionRequestModel,
    _ completion: @escaping (Result<AuthSessionResponseModel, Error>, Int?) -> Void
  ) {
    networkService.execute(MatrixEndpoint.createSession(requestModel: requestModel), completion: completion)
  }
  
  func checkSessionStatus(
    sessionId: String,
    _ completion: @escaping (Result<SessionValidResponseModel, Error>, Int?) -> Void
  ) {
    networkService.execute(MatrixEndpoint.checkSessionStatus(sessionId: sessionId), completion: completion)
  }
  
  func refreshSession(
    sessionId: String,
    _ completion: @escaping (Result<SessionValidResponseModel, Error>, Int?) -> Void
  ) {
    networkService.execute(MatrixEndpoint.refreshSession(sessionId: sessionId), completion: completion)
  }
}
