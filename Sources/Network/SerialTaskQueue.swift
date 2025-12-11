//
//  SerialTaskQueue.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 09/12/25.
//


final class SerialTaskQueue {
  private var currentTask: Task<Void, Never>?
  
  func enqueue(_ operation: @escaping () async -> Void) {
    let previousTask = currentTask
    currentTask = Task {
      await previousTask?.value
      await operation()
    }
  }
  
  func waitForAll() async {
    await currentTask?.value
  }
}
