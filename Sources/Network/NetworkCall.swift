//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation
import Network

public final class NetworkConfig {
  public var baseUrl: String = ""
  public var queryParams: [String: String] = [:]
  public var httpMethod: String = ""
  
  public static let shared = NetworkConfig()
  private init() {}
}

enum ApiError: Error {
    case networkError(Error)
    case serverError(statusCode: Int, data: Data)
    case unknownError
}

protocol NetworkRequest {
    func execute(completion: @escaping (Result<Data, ApiError>) -> Void)
}

final class NetworkManager {
  static let shared = NetworkManager()
  private init() {}
  
  func perform(request: NetworkRequest, completion: @escaping (Result<Data, ApiError>) -> Void) {
    request.execute(completion: completion)
  }
}
