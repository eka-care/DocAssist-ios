//
//  MatrixModels.swift
//  ChatBotAiPackage
//

import Foundation

/// What the chat stream reports to the view model.
enum MatrixStreamEvent: Sendable {
  /// A piece of the answer. Pieces must be appended in order.
  case chunk(String)
  /// A short status line such as "searching". Not part of the answer.
  case progress(String)
  /// Follow-up suggestions.
  case tips([String])
}

enum MatrixError: LocalizedError {
  case notConfigured
  case http(status: Int)
  case invalidResponse
  case server(code: String, message: String)
  case fileUploadFailed
  /// No usable network path, or it dropped mid-request.
  case offline
  /// The server stopped answering.
  case timedOut
  /// The socket closed and could not be reopened.
  case connectionLost
  /// The doctor's Eka token is expired or missing and could not be refreshed (401 `partner_token_expired`).
  case authExpired
  /// Matrix rejected the doctor's Eka token even after a refresh (403 `partner_auth_error`).
  case authRejected
  /// Matrix or a service behind it failed (5xx, `internal_server_error`, `upstream_error`).
  case serviceUnavailable

  var errorDescription: String? {
    switch self {
    case .notConfigured: "Ask AI is not configured."
    case .http(let status): "Request failed with status \(status)."
    case .invalidResponse: "Unexpected response from server."
    case .server(_, let message): message
    case .fileUploadFailed: "Could not upload the attached files."
    case .offline: "You're offline. Check your internet connection and try again."
    case .timedOut: "Ask AI is taking too long to respond. Please try again."
    case .connectionLost: "The connection was lost. Please try again."
    case .authExpired: "Your session has expired. Please sign in again."
    case .authRejected: "Ask AI couldn't verify your account. Please try again later."
    case .serviceUnavailable: "Ask AI is temporarily unavailable. Please try again in a moment."
    }
  }

  /// Maps any failure from the chat stream to what the doctor is shown.
  static func from(_ error: Error) -> MatrixError {
    switch error {
    case let error as MatrixError:
      return error
    case let error as URLError:
      return from(urlError: error)
    case is MatrixSocketClosed:
      return .connectionLost
    case is DecodingError:
      return .invalidResponse
    default:
      return .connectionLost
    }
  }

  static func from(urlError: URLError) -> MatrixError {
    switch urlError.code {
    case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff,
         .callIsActive, .cannotFindHost, .dnsLookupFailed:
      return .offline
    case .timedOut:
      return .timedOut
    case .cannotConnectToHost, .badServerResponse:
      return .serviceUnavailable
    default:
      return .connectionLost
    }
  }

  /// True for transport failures that end the request; the caller must not retry them blindly.
  static func isNetworkFailure(_ error: Error) -> Bool {
    switch error {
    case MatrixError.offline, MatrixError.timedOut: true
    default: false
    }
  }
}

/// A local file ready for the presigned upload.
struct MatrixUploadFile: Sendable {
  static let maxFileSize = 3 * 1024 * 1024
  static let maxFilesPerMessage = 3

  let data: Data
  let mimeType: String
  let fileName: String

  /// Loads the files Matrix accepts (pdf, jpeg, png under 3 MB) from absolute paths or paths relative to Documents.
  static func load(paths: [String]) -> [MatrixUploadFile] {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var files: [MatrixUploadFile] = []
    for path in paths {
      guard files.count < maxFilesPerMessage else { break }
      let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : documents.appendingPathComponent(path)
      guard let mimeType = mimeType(for: url.pathExtension),
            let data = try? Data(contentsOf: url),
            data.count < maxFileSize else {
        print("#Matrix skipped attachment \(url.lastPathComponent)")
        continue
      }
      files.append(MatrixUploadFile(data: data, mimeType: mimeType, fileName: url.lastPathComponent))
    }
    return files
  }

  private static func mimeType(for pathExtension: String) -> String? {
    switch pathExtension.lowercased() {
    case "pdf": "application/pdf"
    case "jpg", "jpeg": "image/jpeg"
    case "png": "image/png"
    default: nil
    }
  }
}

// MARK: - Wire types

struct MatrixTokenResponse: Codable, Sendable {
  let userId: String?
  let sessToken: String
  let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case sessToken = "sess_token"
    case refreshToken = "refresh_token"
  }
}

struct MatrixSessionResponse: Decodable {
  let sessionId: String

  enum CodingKeys: String, CodingKey {
    case sessionId = "session_id"
  }
}

/// GET /med-assist/session: `{ region, data: [MatrixSessionSummary] }`.
struct MatrixSessionListResponse: Decodable {
  let data: [MatrixSessionSummary]
}

struct MatrixSessionSummary: Decodable, Sendable {
  let sessionId: String
  let topic: String?
  let channel: String?
  /// Created-at, epoch seconds.
  let createdAt: TimeInterval?

  enum CodingKeys: String, CodingKey {
    case topic, channel
    case sessionId = "session_id"
    case createdAt = "c_ate"
  }
}

/// GET /med-assist/session/{id}?messages=true
struct MatrixSessionHistoryResponse: Decodable {
  let sessionId: String
  let messages: [MatrixHistoryMessage]?

  enum CodingKeys: String, CodingKey {
    case messages
    case sessionId = "session_id"
  }
}

struct MatrixHistoryMessage: Decodable, Sendable {
  let id: String
  let content: String?
  /// `user` or `assistant`.
  let role: String
  /// Epoch seconds; the server sends null for some user messages.
  let timestamp: TimeInterval?
  let elicitations: [Elicitation]?

  struct Elicitation: Decodable, Sendable {
    let toolId: String?
    let component: String?
    let input: Input?

    struct Input: Decodable, Sendable {
      let text: String?
      let options: [Option]?
    }

    struct Option: Decodable, Sendable {
      let label: String
      let value: String?
    }

    enum CodingKeys: String, CodingKey {
      case component, input
      case toolId = "tool_id"
    }
  }
}

struct MatrixPresignedURL: Decodable, Sendable {
  let id: String
  let url: String
  let fields: [String: String]?
}

/// One server frame: `{ ev, _id, ts, ct, data }`. Each socket message carries one frame.
struct MatrixFrame: Decodable {
  let ev: String
  let ct: String?
  let data: FrameData?

  struct FrameData: Decodable {
    let text: String?
    let progressMsg: String?
    let tips: [String]?
    let urls: [MatrixPresignedURL]?
    let code: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
      case text, tips, urls, code, msg
      case progressMsg = "progress_msg"
    }
  }
}

/// Error body of a failed REST call: `{ "error": { "code", "msg" } }`.
struct MatrixRESTError: Decodable {
  let error: Detail

  struct Detail: Decodable {
    let code: String
    let msg: String
  }
}

/// The socket closed or failed; carries the WebSocket close code (0 when there is none).
enum MatrixSocketClosed: Error {
  case code(Int)
}

enum MatrixErrorCode {
  static let sessionTokenExpired = "sess_token_expired"
  /// Token exchange, 401: the Eka `auth_token` is past its `exp`.
  static let partnerTokenExpired = "partner_token_expired"
  /// Token exchange, 403: bad signature, wrong workspace, replayed `jti`, no `mobile`/`sub`, or no shared secret.
  static let partnerAuthError = "partner_auth_error"
  /// Codes after which the stored session must be dropped and a new one created.
  static let sessionGone: Set<String> = ["session_not_found", "session_not_owned", "session_token_mismatch"]
}
