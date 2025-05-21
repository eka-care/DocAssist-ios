//
//  MRInitializer.swift
//  DocAssist-ios
//
//  Created by Brunda B on 28/04/25.
//

import EkaMedicalRecordsCore

class MRInitializer {
  
  init() {}
  
  static var shared = MRInitializer()
  
  func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String) {
    var ownerId: String = oid
    
    if oid == "" {
      ownerId = SetUIComponents.shared.docOId ?? ""
    }
    registerAuthToken(authToken: authToken, refreshToken: refreshToken, oid: ownerId, bid: bid)
  }
  
  private func registerAuthToken(authToken: String, refreshToken: String, oid: String, bid: String) {
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.filterID = oid
    CoreInitConfigurations.shared.ownerID = bid
  }
  
}
