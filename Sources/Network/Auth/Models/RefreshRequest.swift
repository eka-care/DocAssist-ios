//
//  RefreshRequest.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//


import Foundation

struct RefreshRequest: Codable {
  let refresh: String
  let sess: String
  let clientId: String = "patient-app-ios"
  
  enum CodingKeys: String, CodingKey {
    case refresh = "refresh_token"
    case sess = "access_token"
    case clientId = "client_id"
  }
}
