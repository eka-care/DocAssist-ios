//
//  File.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 04/03/25.
//

import Foundation

class DocAssistFileHelper {
  
  public static func getDocumentDirectoryURL() -> URL {
    guard let documentsDirectory = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask).first else {
      return FileManager.default.temporaryDirectory
    }
    return documentsDirectory
  }
  
}
