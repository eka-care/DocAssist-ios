//
//  AskAIFailureLogger.swift
//  ChatBotAiPackage
//

import Foundation

protocol AskAIFailureSink: Sendable {
  func send(_ properties: [String: String])
}

struct MixpanelFailureSink: AskAIFailureSink {
  func send(_ properties: [String: String]) {
    Task { @MainActor in
      DocAssistEventManager.shared.trackEvent(event: .failure, properties: properties)
    }
  }
}

enum AskAIChatResult {
  case answered
  case stopped
  case failed(MatrixError)
}

struct AskAIChatAttempt {
  let chatId: String
  let messageId: String
  let isRetry: Bool
  let textLength: Int
  let documentsSelected: Int
  let files: [MatrixUploadFile]
  let skipped: [MatrixUploadFile.Skipped]

  private(set) var upload: MatrixUploadDiagnostics?
  private(set) var chunkCount = 0
  private(set) var progressCount = 0
  private(set) var answerLength = 0
  private(set) var tipsCount = 0
  private let startedAt = ContinuousClock.now
  private var firstChunkAt: ContinuousClock.Instant?

  init(
    chatId: String,
    messageId: String,
    isRetry: Bool,
    text: String,
    documentPaths: [String]?,
    loaded: MatrixUploadFile.LoadResult
  ) {
    self.chatId = chatId
    self.messageId = messageId
    self.isRetry = isRetry
    textLength = text.count
    documentsSelected = documentPaths?.count ?? 0
    files = loaded.files
    skipped = loaded.skipped
  }

  mutating func record(_ event: MatrixStreamEvent) {
    switch event {
    case .chunk(let text):
      if firstChunkAt == nil {
        firstChunkAt = ContinuousClock.now
      }
      chunkCount += 1
      answerLength += text.count
    case .progress:
      progressCount += 1
    case .tips(let tips):
      tipsCount = tips.count
    case .elicitation(let text, let options):
      chunkCount += 1
      answerLength += text.count
      tipsCount = options.count
    case .upload(let diagnostics):
      upload = diagnostics
    }
  }

  var elapsed: Duration { ContinuousClock.now - startedAt }
  var timeToFirstChunk: Duration? { firstChunkAt.map { $0 - startedAt } }
}

struct AskAIFailureLogger {
  private let sink: AskAIFailureSink

  init(sink: AskAIFailureSink = MixpanelFailureSink()) {
    self.sink = sink
  }

  func finish(_ attempt: AskAIChatAttempt, result: AskAIChatResult) {
    switch result {
    case .stopped:
      return
    case .answered:
      guard !attempt.skipped.isEmpty else { return }
      sink.send(Self.properties(for: attempt, type: "documents_dropped", stage: "prepare", error: nil))
    case .failed(let error):
      sink.send(Self.properties(for: attempt, type: "chat_failed", stage: Self.stage(of: attempt), error: error))
    }
  }

  private static func stage(of attempt: AskAIChatAttempt) -> String {
    if let upload = attempt.upload, upload.outcome != .uploaded {
      switch upload.outcome ?? .failed {
      case .urlsTimedOut, .urlsRequestFailed, .answeredWithoutUrls, .noUrls:
        return "upload_urls"
      default:
        return "upload"
      }
    }
    return attempt.chunkCount == 0 ? "waiting_for_answer" : "during_answer"
  }

  private static func properties(
    for attempt: AskAIChatAttempt,
    type: String,
    stage: String,
    error: MatrixError?
  ) -> [String: String] {
    var properties: [String: String] = [
      "failure_type": type,
      "failure_stage": stage,
      "chat_id": attempt.chatId,
      "message_id": attempt.messageId,
      "is_retry": String(attempt.isRetry),
      "text_length": String(attempt.textLength),
      "with_documents": String(!attempt.files.isEmpty),
      "documents_selected": String(attempt.documentsSelected),
      "documents_sent": String(attempt.files.count),
      "documents_skipped": String(attempt.skipped.count),
      "chunk_count": String(attempt.chunkCount),
      "progress_count": String(attempt.progressCount),
      "answer_length": String(attempt.answerLength),
      "partial_answer": String(error != nil && attempt.answerLength > 0),
      "tips_count": String(attempt.tipsCount),
      "total_ms": milliseconds(attempt.elapsed)
    ]
    properties["first_chunk_ms"] = attempt.timeToFirstChunk.map(milliseconds)

    if !attempt.files.isEmpty {
      properties["file_types"] = attempt.files.map(\.mimeType).joined(separator: ",")
      properties["file_sizes_kb"] = attempt.files.map { String($0.data.count / 1024) }.joined(separator: ",")
    }

    if !attempt.skipped.isEmpty {
      properties["documents_skipped_reasons"] = attempt.skipped.map(\.reason.rawValue).joined(separator: ",")
      properties["skipped_extensions"] = attempt.skipped.map(\.fileExtension).joined(separator: ",")
      properties["skipped_sizes_kb"] = attempt.skipped.map { $0.sizeKB.map(String.init) ?? "unknown" }.joined(separator: ",")
      properties["skipped_path_kinds"] = attempt.skipped.map(\.pathKind).joined(separator: ",")
    }

    if let upload = attempt.upload {
      properties["upload_outcome"] = upload.outcome?.rawValue ?? "unknown"
      properties["upload_urls_received"] = String(upload.urlCount > 0)
      properties["upload_url_count"] = String(upload.urlCount)
      properties["upload_empty_url_count"] = String(upload.emptyUrlCount)
      properties["upload_uploaded_count"] = String(upload.uploadedCount)
      properties["upload_failed_count"] = String(upload.fileCount - upload.uploadedCount)
      properties["upload_urls_wait_ms"] = upload.urlsWait.map(milliseconds)
      properties["upload_ms"] = upload.uploadTime.map(milliseconds)
      properties["upload_method"] = upload.uploadMethod
      properties["upload_host"] = upload.uploadHost
      properties["upload_failure"] = upload.uploadFailure
    }

    if let error {
      properties["error_type"] = errorType(error)
      properties["error"] = error.errorDescription
      if case .server(let code, _) = error {
        properties["error_code"] = code
      }
    }
    return properties
  }

  private static func errorType(_ error: MatrixError) -> String {
    switch error {
    case .notConfigured: "not_configured"
    case .http(let status): "http_\(status)"
    case .invalidResponse: "invalid_response"
    case .server: "server"
    case .fileUploadFailed: "file_upload_failed"
    case .filesNotAttached: "files_not_attached"
    case .offline: "offline"
    case .timedOut: "timed_out"
    case .connectionLost: "connection_lost"
    case .authExpired: "auth_expired"
    case .authRejected: "auth_rejected"
    case .serviceUnavailable: "service_unavailable"
    }
  }

  private static func milliseconds(_ duration: Duration) -> String {
    let parts = duration.components
    return String(parts.seconds * 1000 + parts.attoseconds / 1_000_000_000_000_000)
  }
}
