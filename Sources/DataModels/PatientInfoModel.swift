//
//  PatientInfoModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/07/25.
//


public struct PatientInfoModel {
    public let name: String?
    public let dob: String?
    public let gender: String?
    public let userUUID: String?
    public let userOID: String?
    public let phoneNumber: String?
  
  public init(name: String?, dob: String?, gender: String?, userUUID: String?, userOID: String?, phoneNumber: String?) {
    self.name = name
    self.dob = dob
    self.gender = gender
    self.userUUID = userUUID
    self.userOID = userOID
    self.phoneNumber = phoneNumber
  }
}
