//
//  MatrixClient.swift
//  ChatBotAiPackage
//
//  Talks to the Matrix med-assist backend over its WebSocket channel:
//  token exchange -> session create -> socket (auth, conn) -> chat frames.
//

import Foundation

actor MatrixClient {

  static let shared = MatrixClient()

  private let urlSession = URLSession(configuration: .default)
  private let sessionStore = MatrixSessionStore()

  private var tokens: MatrixTokenResponse?
  private var tokenIdentity: String?
  private var tokenTask: Task<MatrixTokenResponse, Error>?
  private var sessionTasks: [String: Task<String, Error>] = [:]
  /// One socket at a time, for the Matrix session currently chatting.
  private var socket: (sessionId: String, task: URLSessionWebSocketTask)?

  private var config: NetworkConfig { NetworkConfig.shared }

  // MARK: - Chat

  /// Sends one user message (with optional attachments) and streams the answer.
  /// Cancelling the consuming task cancels the request.
  nonisolated func chat(
    localSessionId: String,
    text: String,
    files: [MatrixUploadFile]
  ) -> AsyncThrowingStream<MatrixStreamEvent, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          try await runChat(localSessionId: localSessionId, text: text, files: files) { event in
            continuation.yield(event)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func runChat(
    localSessionId: String,
    text: String,
    files: [MatrixUploadFile],
    emit: @Sendable (MatrixStreamEvent) -> Void
  ) async throws {
    guard !files.isEmpty else {
      try await exchangeFrames(ct: "text", data: ["text": text], localSessionId: localSessionId) { frame in
        forward(frame, emit: emit)
      }
      return
    }

    /// File step 1: announce the files, receive presigned upload targets.
    var targets: [MatrixPresignedURL] = []
    try await exchangeFrames(
      ct: "file",
      data: [
        "extensions": files.map(\.mimeType),
        "file_sizes": files.map(\.data.count)
      ],
      localSessionId: localSessionId
    ) { frame in
      guard frame.ev == "chat", frame.ct == "file", let urls = frame.data?.urls, !urls.isEmpty else { return false }
      targets = urls
      return true
    }

    /// File step 2: upload.
    let uploadedIds = await upload(files, to: targets)
    guard !uploadedIds.isEmpty else { throw MatrixError.fileUploadFailed }

    /// File step 3: send the uploaded ids with the text, stream the answer.
    var data: [String: Any] = ["urls": uploadedIds]
    if !text.isEmpty {
      data["text"] = text
    }
    try await exchangeFrames(ct: "file", data: data, localSessionId: localSessionId) { frame in
      forward(frame, emit: emit)
    }
  }

  /// Maps a server frame to a stream event. Never ends the read early.
  private func forward(_ frame: MatrixFrame, emit: @Sendable (MatrixStreamEvent) -> Void) -> Bool {
    guard frame.ev == "stream", let data = frame.data else { return false }
    switch frame.ct {
    case "text":
      if let progress = data.progressMsg, !progress.isEmpty {
        emit(.progress(progress))
      } else if let text = data.text, !text.isEmpty {
        emit(.chunk(text))
      }
    case "tips":
      if let tips = data.tips, !tips.isEmpty {
        emit(.tips(tips))
      }
    default:
      break
    }
    return false
  }

  /// Sends one chat frame over the session's socket and hands each server frame
  /// to `onFrame` until `eos` arrives or `onFrame` returns true. Before any
  /// content arrives, it recovers once from a closed socket, an expired token or
  /// a lost session, then sends the frame again.
  private func exchangeFrames(
    ct: String,
    data: [String: Any],
    localSessionId: String,
    onFrame: (MatrixFrame) async throws -> Bool
  ) async throws {
    var recovered = false
    while true {
      var receivedContent = false
      do {
        let task = try await connectedSocket(localSessionId: localSessionId)
        try await send(frame(ev: "chat", ct: ct, data: data), on: task)
        while true {
          let frame = try await receiveFrame(on: task)
          switch frame.ev {
          case "eos":
            return
          case "err":
            throw MatrixError.server(
              code: frame.data?.code ?? "",
              message: frame.data?.msg ?? "Something went wrong. Please try again."
            )
          case "pong", "sync", "conn":
            continue
          default:
            receivedContent = true
            if try await onFrame(frame) {
              return
            }
          }
        }
      } catch {
        guard !receivedContent, !recovered, !Task.isCancelled,
              await recover(from: error, localSessionId: localSessionId) else {
          throw error
        }
        recovered = true
        closeSocket()
      }
    }
  }

  /// Returns true when the failure was repaired and the frame should be sent again.
  private func recover(from error: Error, localSessionId: String) async -> Bool {
    switch error {
    case MatrixSocketClosed.code(let code):
      switch code {
      case 4401:
        await refreshTokens()
      case 4403:
        clearTokens()
      case 4404:
        sessionStore.remove(localSessionId: localSessionId, identity: config.identity)
      default:
        /// Dropped or idle-closed socket: reconnecting is enough.
        break
      }
      return true
    case MatrixError.server(let code, _):
      if code == MatrixErrorCode.sessionTokenExpired {
        await refreshTokens()
        return true
      }
      if MatrixErrorCode.sessionGone.contains(code) {
        sessionStore.remove(localSessionId: localSessionId, identity: config.identity)
        return true
      }
      return false
    default:
      return false
    }
  }

  // MARK: - Socket

  /// The open, authenticated socket for this chat's Matrix session; opens one when needed.
  private func connectedSocket(localSessionId: String) async throws -> URLSessionWebSocketTask {
    let sessionId = try await matrixSessionId(for: localSessionId)
    if let socket, socket.sessionId == sessionId, socket.task.state == .running, socket.task.closeCode == .invalid {
      return socket.task
    }
    closeSocket()

    let bearer = try await bearerToken()
    var request = try makeRequest(path: "/ws/med-assist/session/\(sessionId)/", method: "GET", bearer: nil)
    guard let httpURL = request.url, var components = URLComponents(url: httpURL, resolvingAgainstBaseURL: false) else {
      throw MatrixError.notConfigured
    }
    components.scheme = components.scheme == "http" ? "ws" : "wss"
    request.url = components.url
    request.timeoutInterval = 60

    let task = urlSession.webSocketTask(with: request)
    task.resume()
    socket = (sessionId, task)

    /// Handshake: auth frame first, then wait for `conn` before chatting.
    try await send(frame(ev: "auth", data: ["token": bearer]), on: task)
    while true {
      let frame = try await receiveFrame(on: task)
      switch frame.ev {
      case "conn":
        return task
      case "err":
        throw MatrixError.server(code: frame.data?.code ?? "", message: frame.data?.msg ?? "Could not connect.")
      default:
        continue
      }
    }
  }

  /// Next server frame. Answers `ping` itself and skips messages that are not frames.
  /// Cancelling the calling task closes the socket.
  private func receiveFrame(on task: URLSessionWebSocketTask) async throws -> MatrixFrame {
    while true {
      let message: URLSessionWebSocketTask.Message
      do {
        message = try await withTaskCancellationHandler {
          try await task.receive()
        } onCancel: {
          task.cancel(with: .goingAway, reason: nil)
        }
      } catch {
        if Task.isCancelled {
          throw CancellationError()
        }
        throw MatrixSocketClosed.code(task.closeCode.rawValue)
      }
      let data: Data
      switch message {
      case .string(let text):
        data = Data(text.utf8)
      case .data(let bytes):
        data = bytes
      @unknown default:
        continue
      }
      guard let frame = try? JSONDecoder().decode(MatrixFrame.self, from: data) else { continue }
      if frame.ev == "ping" {
        try await send(self.frame(ev: "pong"), on: task)
        continue
      }
      return frame
    }
  }

  private func send(_ frame: Data, on task: URLSessionWebSocketTask) async throws {
    do {
      try await task.send(.string(String(decoding: frame, as: UTF8.self)))
    } catch {
      throw MatrixSocketClosed.code(task.closeCode.rawValue)
    }
  }

  private func closeSocket() {
    socket?.task.cancel(with: .normalClosure, reason: nil)
    socket = nil
  }

  /// Wire frame: `{ ev, ct?, _id, ts, data? }`.
  private func frame(ev: String, ct: String? = nil, data: [String: Any]? = nil) throws -> Data {
    let now = Int(Date().timeIntervalSince1970 * 1000)
    var frame: [String: Any] = ["ev": ev, "_id": String(now), "ts": now]
    if let ct {
      frame["ct"] = ct
    }
    if let data {
      frame["data"] = data
    }
    return try JSONSerialization.data(withJSONObject: frame)
  }

  // MARK: - File upload

  /// Uploads each file to its presigned target, in order. Stops at the first
  /// failure and returns the ids that did upload.
  private func upload(_ files: [MatrixUploadFile], to targets: [MatrixPresignedURL]) async -> [String] {
    var uploadedIds: [String] = []
    for (file, target) in zip(files, targets) {
      guard let url = URL(string: target.url.trimmingCharacters(in: .whitespaces)), !target.url.isEmpty else { continue }
      var request = URLRequest(url: url)
      let body: Data
      if let fields = target.fields {
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        body = multipartBody(fields: fields, file: file, boundary: boundary)
      } else {
        request.httpMethod = "PUT"
        request.setValue(file.mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        body = file.data
      }
      do {
        let (_, response) = try await urlSession.upload(for: request, from: body)
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else { break }
        uploadedIds.append(target.id)
      } catch {
        print("#Matrix upload failed: \(error.localizedDescription)")
        break
      }
    }
    return uploadedIds
  }

  /// Presigned POST form: policy fields first, file last.
  private func multipartBody(fields: [String: String], file: MatrixUploadFile, boundary: String) -> Data {
    var body = Data()
    for (key, value) in fields {
      body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8))
    }
    body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(file.fileName)\"\r\nContent-Type: \(file.mimeType)\r\n\r\n".utf8))
    body.append(file.data)
    body.append(Data("\r\n--\(boundary)--\r\n".utf8))
    return body
  }

  // MARK: - Session

  private func matrixSessionId(for localSessionId: String) async throws -> String {
    let identity = config.identity
    if let sessionId = sessionStore.sessionId(localSessionId: localSessionId, identity: identity) {
      return sessionId
    }
    if let task = sessionTasks[localSessionId] {
      return try await task.value
    }
    let task = Task { try await createSession() }
    sessionTasks[localSessionId] = task
    defer { sessionTasks[localSessionId] = nil }
    let sessionId = try await task.value
    sessionStore.save(sessionId: sessionId, localSessionId: localSessionId, identity: identity)
    return sessionId
  }

  /// POST /med-assist/session
  private func createSession() async throws -> String {
    var body: [String: Any] = [:]
    let bearer = try await bearerToken()
    if let userId = tokens?.userId {
      body["user_id"] = userId
    }
    let context = config.sessionContext.filter { !$0.value.isEmpty }
    if !context.isEmpty {
      body["session_context"] = context
    }
    let data = try await sendREST(path: "/med-assist/session", body: body, bearer: bearer)
    return try JSONDecoder().decode(MatrixSessionResponse.self, from: data).sessionId
  }

  /// Sends an authenticated REST call, refreshing the token once on a 401.
  private func sendREST(path: String, body: [String: Any], bearer: String) async throws -> Data {
    var request = try makeRequest(path: path, method: "POST", bearer: bearer)
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    var (data, response) = try await urlSession.data(for: request)
    if (response as? HTTPURLResponse)?.statusCode == 401 {
      await refreshTokens()
      let newBearer = try await bearerToken()
      request.setValue("Bearer \(newBearer)", forHTTPHeaderField: "Authorization")
      (data, response) = try await urlSession.data(for: request)
    }
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(status) else { throw restError(status: status, body: data) }
    return data
  }

  // MARK: - Tokens

  /// Current sess token; runs the token exchange once (single flight) when there is none.
  private func bearerToken() async throws -> String {
    if tokenIdentity != config.identity {
      clearTokens()
      tokenIdentity = config.identity
    }
    if let tokens {
      return tokens.sessToken
    }
    if let tokenTask {
      return try await tokenTask.value.sessToken
    }
    let task = Task { try await exchangeTokens() }
    tokenTask = task
    defer { tokenTask = nil }
    let result = try await task.value
    tokens = result
    return result.sessToken
  }

  /// POST /med-assist/auth/token-exchange. Sends only the agent id; the doctor is identified through `session_context`.
  private func exchangeTokens() async throws -> MatrixTokenResponse {
    var request = try makeRequest(path: "/med-assist/auth/token-exchange", method: "POST", bearer: nil)
    request.httpBody = try JSONSerialization.data(withJSONObject: ["agent_id": config.agentId])
    return try await decodeTokenResponse(for: request)
  }

  /// Rotates the token pair. On failure the pair is dropped, so the next call
  /// runs a fresh exchange.
  private func refreshTokens() async {
    guard let current = tokens else { return }
    do {
      var request = try makeRequest(
        path: "/med-assist/auth/token-exchange",
        query: [URLQueryItem(name: "type", value: "refresh")],
        method: "POST",
        bearer: current.sessToken
      )
      request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": current.refreshToken])
      tokens = try await decodeTokenResponse(for: request)
    } catch {
      clearTokens()
    }
  }

  private func decodeTokenResponse(for request: URLRequest) async throws -> MatrixTokenResponse {
    let (data, response) = try await urlSession.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(status) else { throw restError(status: status, body: data) }
    return try JSONDecoder().decode(MatrixTokenResponse.self, from: data)
  }

  /// Turns a failed REST response into an error, keeping the server's `{error: {code, msg}}` when present.
  private func restError(status: Int, body: Data) -> MatrixError {
    guard let error = try? JSONDecoder().decode(MatrixRESTError.self, from: body).error else {
      return .http(status: status)
    }
    print("#Matrix HTTP \(status): \(error.code) - \(error.msg)")
    return .server(code: error.code, message: error.msg)
  }

  private func clearTokens() {
    tokens = nil
    tokenTask?.cancel()
    tokenTask = nil
  }

  // MARK: - Request building

  private func makeRequest(
    path: String,
    query: [URLQueryItem] = [],
    method: String,
    bearer: String?
  ) throws -> URLRequest {
    guard !config.baseUrl.isEmpty, !config.agentId.isEmpty,
          var components = URLComponents(string: config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path) else {
      throw MatrixError.notConfigured
    }
    if !query.isEmpty {
      components.queryItems = query
    }
    guard let url = components.url else { throw MatrixError.notConfigured }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.agentId, forHTTPHeaderField: "X-agent-id")
    request.setValue(config.channel, forHTTPHeaderField: "x-channel")
    request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Timezone")
    if let bearer {
      request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
    }
    return request
  }
}

/// Persists which Matrix session each local chat session talks to, per doctor identity.
struct MatrixSessionStore: Sendable {
  private let defaultsKey = "DocAssistMatrixSessionIds"

  func sessionId(localSessionId: String, identity: String) -> String? {
    stored()[key(localSessionId, identity)]
  }

  func save(sessionId: String, localSessionId: String, identity: String) {
    var sessions = stored()
    sessions[key(localSessionId, identity)] = sessionId
    UserDefaults.standard.set(sessions, forKey: defaultsKey)
  }

  func remove(localSessionId: String, identity: String) {
    var sessions = stored()
    sessions[key(localSessionId, identity)] = nil
    UserDefaults.standard.set(sessions, forKey: defaultsKey)
  }

  private func stored() -> [String: String] {
    UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
  }

  private func key(_ localSessionId: String, _ identity: String) -> String {
    "\(identity)|\(localSessionId)"
  }
}
