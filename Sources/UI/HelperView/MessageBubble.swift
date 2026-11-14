//
//  MessageBubble.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//
//  One row of the conversation: the message, its actions, and (for the
//  latest answer) the suggested follow-ups.
//

import SwiftUI
import EkaVoiceToRx
import EkaPDFMaker

enum SuggestionsState {
  case generate
  case loading
  case noMore
}

struct MessageBubble: View {
  let message: ChatMessage
  let m: String?
  let url: [String]?
  let viewModel: ChatViewModel
  @State var suggestionViewModel = SuggestionsViewModel()
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  var onClickOfFeedback: () -> Void
  var onClickOfCopy: () -> Void
  var messages: [ChatMessage]

  private enum Rating { case good, bad }
  @State private var rating: Rating?
  @State private var copied = false
  @State private var hapticTick = 0

  private var isLatest: Bool { message.id == messages.last?.id }
  /// The answer that is still arriving gets no actions until it is complete.
  private var isStreaming: Bool { isLatest && viewModel.streamStarted }
  private var answerText: String { m ?? "" }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      switch message.role {
      case .user:
        UserMessageBubble(text: m, imageUrls: url)
      case .assistant:
        assistantRow
        if !isStreaming, !answerText.isEmpty {
          actionsRow
            .transition(.opacity)
        }
        if isLatest, !isStreaming, let suggestions = message.suggestions, !suggestions.isEmpty {
          SuggestionView(suggestionText: suggestions, viewModel: viewModel)
            .padding(.top, 6)
        }
      case .voiceToRx:
        VoiceToRxChip()
      }
    }
    .padding(.vertical, 2)
    .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
    .animation(.easeInOut(duration: 0.2), value: isStreaming)
  }

  // MARK: - Assistant

  private var assistantRow: some View {
    HStack(alignment: .top, spacing: 10) {
      BotAvatarImage()
        .padding(.top, 3)
      AssistantMessageText(text: answerText)
    }
    .contextMenu {
      Button(action: copy) {
        Label("Copy", systemImage: "doc.on.doc")
      }
      Button(action: sharePDF) {
        Label("Share as PDF", systemImage: "square.and.arrow.up")
      }
    }
  }

  /// Copy, rate and share, aligned with the answer text.
  private var actionsRow: some View {
    HStack(spacing: 2) {
      actionButton(copied ? "checkmark" : "doc.on.doc", label: "Copy", action: copy)
      actionButton(rating == .good ? "hand.thumbsup.fill" : "hand.thumbsup", label: "Good answer") { rate(.good) }
      actionButton(rating == .bad ? "hand.thumbsdown.fill" : "hand.thumbsdown", label: "Bad answer") { rate(.bad) }
      actionButton("square.and.arrow.up", label: "Share as PDF", action: sharePDF)
    }
    .padding(.leading, 24)
  }

  private func actionButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .contentTransition(.symbolEffect(.replace))
        .frame(width: 36, height: 32)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  // MARK: - Actions

  private func copy() {
    UIPasteboard.general.string = answerText
    hapticTick += 1
    withAnimation { copied = true }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      withAnimation { copied = false }
    }
    onClickOfCopy()
    track("copy")
  }

  private func rate(_ newRating: Rating) {
    hapticTick += 1
    withAnimation { rating = rating == newRating ? nil : newRating }
    onClickOfFeedback()
    track(newRating == .good ? "good" : "bad")
  }

  private func sharePDF() {
    hapticTick += 1
    track("sharepdf")
    let fileURL = PDFRenderer().renderSinglePage(
      headerView: AnyView(DTPDFHeaderView(
        data: DTPDFHeaderViewData.formDeepthoughtHeaderViewData(doctorName: "DR.\(SetUIComponents.shared.docName ?? "")", clinicName: "", address: "")
      )),
      bodyView: AnyView(PdfBodyView(text: answerText))
    )
    present(shareSheetFor: fileURL)
  }

  private func track(_ type: String) {
    DocAssistEventManager.shared.trackEvent(
      event: .chatResponseActions,
      properties: ["type": type, "session_id": message.sessionId, "text": m]
    )
  }

  private func present(shareSheetFor url: URL?) {
    guard let url,
          let root = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    else { return }
    var presenter = root
    while let presented = presenter.presentedViewController {
      presenter = presented
    }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    presenter.present(activityVC, animated: true)
  }
}

/// Marks where a Voice-to-Rx recording was started in the chat.
struct VoiceToRxChip: View {
  var body: some View {
    Label("Voice-to-Rx session", systemImage: "waveform")
      .font(.footnote.weight(.semibold))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .chatGlass(in: Capsule(), interactive: false)
  }
}
