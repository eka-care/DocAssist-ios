//
//  matrixEndpoint.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//

import Alamofire

enum MatrixEndpoint {
  case createSession
  case checkSessionStatus
  case refreshSession
}

extension MatrixEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
    case .createSession:
      AF.request("https://matrix.eka.care/reloaded/med-assist/session",
                 method: .post,
                 headers: [
                  "Content-Type": "application/json",
                  "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
                ],
                interceptor: NetworkRequestInterceptor()
      ).validate()
    case .checkSessionStatus:
      AF.request("https://matrix.eka.care/reloaded/med-assist/session",
                 method: .post,
                 headers: [
                  "Content-Type": "application/json",
                  "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
                ],
                interceptor: NetworkRequestInterceptor()
      ).validate()
    case .refreshSession:
      AF.request("https://matrix.eka.care/reloaded/med-assist/session",
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
