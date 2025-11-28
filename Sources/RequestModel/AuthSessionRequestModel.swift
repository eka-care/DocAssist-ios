//
//  AuthSessionRequestModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//

import Foundation

struct AuthSessionRequestModel: Encodable {
  let uerId: String
  
  enum CodingKeys: String, CodingKey {
    case uerId = "user_id"
  }
}
