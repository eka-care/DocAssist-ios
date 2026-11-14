//
//  SuggestionView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//
//  Follow-up questions offered under an answer and on an empty chat.
//

import SwiftUI

/// Follow-ups under the latest answer, aligned with the answer text.
struct SuggestionView: View {
  var suggestionText: [String]
  var viewModel: ChatViewModel

  init(suggestionText: [String], viewModel: ChatViewModel) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Suggested follow-ups")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
      SuggestionsComponentView(suggestionText: suggestionText, viewModel: viewModel)
    }
    .padding(.leading, 30)
  }
}

/// Tappable glass chips; tapping sends the suggestion as the doctor's message.
struct SuggestionsComponentView: View {
  var suggestionText: [String]
  var viewModel: ChatViewModel
  @State private var sentTick = 0

  var body: some View {
    ChatGlassContainer(spacing: 8) {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(suggestionText, id: \.self) { suggestion in
          Button {
            sentTick += 1
            Task {
              await viewModel.sendMessage(newMessage: suggestion, imageUrls: nil, documentPaths: nil, sessionId: viewModel.vmssid)
            }
          } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(suggestion)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
              Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .chatGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          .disabled(viewModel.streamStarted)
          .opacity(viewModel.streamStarted ? 0.5 : 1)
        }
      }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: sentTick)
  }
}
