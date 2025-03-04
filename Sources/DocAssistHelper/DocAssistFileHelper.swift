//
//  File.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 04/03/25.
//

import Foundation

class DocAssistFileHelper {
  
  public static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
}
