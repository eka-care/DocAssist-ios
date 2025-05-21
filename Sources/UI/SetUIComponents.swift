//
//  File.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 26/11/24.
//

import Foundation
import SwiftUI
import EkaVoiceToRx

public class SetUIComponents {
  
  public var userBackGroundColor: Color?
  public var userAllChatBackgroundColor: UIImage?
  public var usertextColor: Color?
  public var botBackGroundColor: Color?
  public var botTextColor: Color?
  public var chatIcon: UIImage?
  public var userIcon: UIImage?
  public var chatHistoryTitle: String?
  public var chatTitle: String?
  public var newChatButtonText: String?
  public var newChatButtonImage: UIImage?
  public var emptyChatImage: UIImage?
  public var emptyChatTitle: String?
  public var ipadBgColor: UIImage?
  public var chatBorder: Color?
  public var subTitleForHistory: String?
  public var emptyHistoryBgColor: Color?
  public var emptyHistoryFgColor: Color?
  public var ipadEmptyChatView: UIImage?
  public var generalChatDefaultSuggestion: [String]?
  public var patientChatDefaultSuggestion: [String]?
  public var docOId: String?
  public var docUUId: String?
  public var docName: String?
  public weak var v2rxDelegate: FloatingVoiceToRxDelegate?
  
  public static let shared = SetUIComponents()

  private init() {}
  
}
