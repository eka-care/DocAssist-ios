//
//  MatrixTokenStore.swift
//  ChatBotAiPackage
//
//  Keeps the Matrix sess/refresh token pair in the Keychain, one item per
//  doctor identity, so a relaunch reuses it instead of running a new exchange.
//

import Foundation
import Security

struct MatrixTokenStore: Sendable {
  static let service = "care.eka.docassist.matrix.tokens"

  func tokens(identity: String) -> MatrixTokenResponse? {
    var query = baseQuery(identity: identity)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data
    else { return nil }
    return try? JSONDecoder().decode(MatrixTokenResponse.self, from: data)
  }

  func save(_ tokens: MatrixTokenResponse, identity: String) {
    guard let data = try? JSONEncoder().encode(tokens) else { return }

    let query = baseQuery(identity: identity)
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
    }
  }

  func remove(identity: String) {
    SecItemDelete(baseQuery(identity: identity) as CFDictionary)
  }

  private func baseQuery(identity: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: identity
    ]
  }
}

public enum DocAssistMatrixTokens {
  /// Deletes every stored Matrix token pair. Call on logout.
  public static func clearAll() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: MatrixTokenStore.service
    ]
    SecItemDelete(query as CFDictionary)
  }
}
