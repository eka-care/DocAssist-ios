//
//  RefreshResponse.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

// MARK: - RefreshResponse
struct RefreshResponse: Codable {
  let refresh: String?
  let sess: String?
  
  enum CodingKeys: String, CodingKey {
    case refresh = "refresh_token"
    case sess = "access_token"
  }
}
 
