//
//  NetworkMonitor.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 11/07/25.
//
import Foundation
import Network

@MainActor
class NetworkMonitor: ObservableObject {
  @Published var isConnected: Bool = true
  
  private var monitor: NWPathMonitor
  private let queue = DispatchQueue.global(qos: .background)
  
  init() {
    monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in
      DispatchQueue.main.async {
        self.isConnected = path.status == .satisfied
      }
    }
    monitor.start(queue: queue)
  }
  
  deinit {
    monitor.cancel()
  }
}
