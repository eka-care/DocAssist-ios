//
//  matrixEndpoint.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//

import Alamofire

enum MatrixEndpoint {
  case createSession(requestModel: AuthSessionRequestModel)
  case checkSessionStatus(sessionId: String)
  case refreshSession(sessionId: String)
}

extension MatrixEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
    case .createSession(let requestModel):
      AF.request("https://matrix.eka.care/reloaded/med-assist/session",
                 method: .post,
                 parameters: requestModel,
                 encoder: JSONParameterEncoder.default,
                 headers: [
                  "Content-Type": "application/json",
                  "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
                ],
                interceptor: NetworkRequestInterceptor()
      ).validate()
    case let .checkSessionStatus(sessionId):
      AF.request("https://matrix.eka.care/reloaded/med-assist/session/\(sessionId)",
                 method: .get,
                 headers: [
                  "Content-Type": "application/json",
                  "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
                ],
                interceptor: NetworkRequestInterceptor()
      ).validate()
    case let .refreshSession(sessionId):
      AF.request("https://matrix.eka.care/med-assist/reloaded/session/\(sessionId)/refresh",
                 method: .post,
                 headers: [
                  "Content-Type": "application/json",
                  "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
                ],
                interceptor: NetworkRequestInterceptor()
      ).validate()
    }
  }
}
