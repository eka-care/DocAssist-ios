//
//  RequestMetadata.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation
import Alamofire
import SwiftProtobuf

// TODO: - Remove unnecssary functions

struct RequestMetadata: Codable {
  public let statusCode: Int?
  public let allHeaders: [String: String]?
}

/// Use this as the basis of all CRUD network requests
protocol Networking: Sendable {
  func execute<T: Decodable>(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<T, Error>, Int?) -> Void
  )
  
  func execute(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )

  func execute<T: Decodable>(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<T, EkaAPIError>, Int?) -> Void
  )
}

// MARK: - Extension with default implementation
extension Networking {
  func execute<T: Decodable>(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<T, Error>, Int?) -> Void
  ) {
    let request = requestProvider.urlRequest
    request.responseDecodable(of: T.self) { response in
      switch response.result {
      case .success(let decodedObject):
        completion(.success(decodedObject), response.response?.statusCode)
      case .failure(let error):
        completion(.failure(error), response.response?.statusCode)
      }
    }
  }
  
  func execute(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    let request = requestProvider.urlRequest
    request.response { response in
      if let error = response.error {
        completion(.failure(error), response.response?.statusCode)
        return
      }
      completion(.success(true), response.response?.statusCode)
    }
  }
  
  func execute<T: Decodable>(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<T, EkaAPIError>, Int?) -> Void
  ) {
    let request = requestProvider.urlRequest
    request.ekaErrorResponseSerializer(of: T.self) { result, statusCode in
      completion(result, statusCode)
    }
  }
  
  func execute<T: Decodable>(
    _ requestProvider: RequestProvider,
    completion: @escaping (Result<T, APIError>, Int?) -> Void
  ) {
    let request = requestProvider.urlRequest
    
    request.responseData { response in
      let statusCode = response.response?.statusCode
      
      switch response.result {
      case .success(let data):
        if let decoded = try? JSONDecoder().decode(T.self, from: data) {
          completion(.success(decoded), statusCode)
        } else if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
          completion(.failure(apiError), statusCode)
        } else {
          // decoding failed and no fallback returned
          debugPrint("Failed to decode both T and APIError")
        }
        
      case .failure:
        if let data = response.data,
           let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
          completion(.failure(apiError), statusCode)
        } else {
          debugPrint("Failed to decode APIError from failed response")
        }
      }
    }
  }
}

// MARK: - Custom serializer for Eka endpoints except CoWIN APIs

struct EkaAPIError: Codable, Error {
  public let error: EkaErrorMessage
  
  public struct EkaErrorMessage: Codable, Error {
    public let message: String?
    public let type: String?
  }
}

final class EkaErrorResponseSerializer<T: Decodable>: ResponseSerializer, @unchecked Sendable {
  
  private let decoder = JSONDecoder()
  private let successSerializer: DecodableResponseSerializer<T>
  private let errorSerializer: DecodableResponseSerializer<EkaAPIError>
  
  init() {
    self.successSerializer = DecodableResponseSerializer<T>(decoder: decoder)
    self.errorSerializer = DecodableResponseSerializer<EkaAPIError>(decoder: decoder)
  }
  
  public func serialize(
    request: URLRequest?,
    response: HTTPURLResponse?,
    data: Data?,
    error: Error?
  ) throws -> Result<T, EkaAPIError> {
    
    guard error == nil else {
      debugPrint("Error in custom serializer \(String(describing: error?.localizedDescription))")
      return .failure(EkaAPIError(error: .init(message: "Something went wrong", type: nil)))
    }
    
    guard let response = response else { return .failure(EkaAPIError(error: .init(message: "Something went wrong", type: nil))) }
    
    debugPrint("Response code - \(response.statusCode)")
    
    do {
      if response.statusCode < 200 || response.statusCode >= 300 {
        let result = try errorSerializer.serialize(request: request, response: response, data: data, error: nil)
        return .failure(result)
      } else {
        let result = try successSerializer.serialize(request: request, response: response, data: data, error: nil)
        return .success(result)
      }
    } catch(let error) {
      debugPrint("Error in catch block of EkaErrorResponseSerializer custom serializer\(error)")
      return .failure(EkaAPIError(error: .init(message: "Something went wrong", type: nil)))
    }
    
  }
  
}

extension DataRequest {
  @discardableResult
  func ekaErrorResponseSerializer<T: Decodable>(
    queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
    of t: T.Type,
    completionHandler: @escaping (Result<T, EkaAPIError>, Int?) -> Void) -> Self {
      return response(queue: .main, responseSerializer: EkaErrorResponseSerializer<T>()) { response in
        switch response.result {
        case .success(let result):
          completionHandler(result, response.response?.statusCode)
        case .failure(let error):
          debugPrint("ERROR IN RESPONSE DECODABLE\(error)")
          completionHandler(.failure(EkaAPIError(error: .init(message: "Something went wrong", type: nil))), response.response?.statusCode)
        }
      }
      .validate(statusCode: 200...599)
    }
}

public struct APIError: Decodable, Error {
  public let status: String?
  public let error: APIErrorDetail?
  public let txn_id: String?
  public let b_id: String?
}

public struct APIErrorDetail: Decodable {
  public let code: String?
  public let message: String?
  public let display_message: String?
}
