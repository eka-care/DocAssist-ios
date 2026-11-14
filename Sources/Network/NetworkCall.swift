//
//  LocalNetworkCall.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation
import Network

/// Host-supplied configuration for the Matrix doc-assist backend.
public final class NetworkConfig: @unchecked Sendable {
  /// Matrix REST base, e.g. `https://matrix.eka.care/reloaded`.
  public var baseUrl: String = ""
  /// Base64 `<uuid>#<wid>` agent id, sent as `X-agent-id` and in the token exchange body.
  public var agentId: String = ""
  /// Surface the chat is drawn in; sent as `x-channel`.
  public var channel: String = "widget"
  /// Returns the doctor's current Eka access token, sent as `auth_token` in the token exchange body.
  /// Read on every exchange so a refreshed token is always picked up.
  public var authTokenProvider: @Sendable () -> String? = { nil }
  /// Extra keys sent in `session_context` when a Matrix session is created (doctor, patient, business, region).
  public var sessionContext: [String: String] = [:]

  public static let shared = NetworkConfig()
  private init() {}

  /// Identifies the signed-in doctor/workspace, so tokens and sessions are never shared across identities.
  var identity: String {
    [agentId, sessionContext["d_oid"] ?? "", sessionContext["b_id"] ?? ""].joined(separator: "|")
  }
}

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
