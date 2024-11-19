//
//  SwiftDataRepoContext.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
import SwiftData

@MainActor
class SwiftDataRepoContext {
  
  let modelContext: ModelContext = {
    do {
      let container = try ModelContainer(for: ChatMessageModel.self,SessionDataModel.self)
      let ctx = ModelContext(container)
      return ctx
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }()
}
