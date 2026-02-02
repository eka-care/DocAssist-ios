//
//  AuthApiService.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


final class MatrixApiService: MatrixProvider, Sendable {
  static let shared = MatrixApiService()
  let networkService: Networking = NetworkService.shared
  
  private init() {}
}
