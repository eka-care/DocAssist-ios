//
//  File.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/01/25.
//

import Foundation

public protocol NavigateToPatientDirectory {
  func navigateToPatientDirectory()
}

public protocol ConvertVoiceToText {
  func convertVoiceToText(audioFileURL: URL, completion: @escaping (String) -> Void)
}

