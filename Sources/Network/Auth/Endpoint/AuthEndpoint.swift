//
//  AuthEndpoint.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Alamofire

enum AuthEndpoint {
  case tokenRefresh(refreshRequest: RefreshRequest)
}

extension AuthEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
    case .tokenRefresh(let refreshRequest):
      AF.request(
        "https://api.eka.care/connect-auth/v1/account/refresh-token",
        method: .post,
        parameters: refreshRequest,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
