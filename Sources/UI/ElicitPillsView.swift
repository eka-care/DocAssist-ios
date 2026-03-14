//
//  ElicitPillsView.swift
//  DocAssist-ios
//
//  Created by Brunda B on 13/03/26.
//

import SwiftUI
import EkaUI

/// Renders elicitation pill / multi-select options from a tool event.
/// Pills are trailing-aligned (right side) to signal that the user is choosing a response.
struct ElicitPillsView: View {
  let suggestions: [String]
  let viewModel: ChatViewModel
  let isMultiSelect: Bool

  @State private var selected: Set<String> = []

  var body: some View {
    VStack(alignment: .trailing, spacing: EkaSpacing.spacingXs) {
      ForEach(suggestions, id: \.self) { option in
        Button {
          if isMultiSelect {
            if selected.contains(option) {
              selected.remove(option)
            } else {
              selected.insert(option)
            }
          } else {
            sendMessage(option)
          }
        } label: {
          HStack(spacing: EkaSpacing.spacingXs) {
            if isMultiSelect {
              Image(systemName: selected.contains(option) ? "checkmark.square.fill" : "square")
                .foregroundColor(selected.contains(option) ? Color.primaryprimary : Color.neutrals400)
                .font(.system(size: 18))
            }

            Text(option)
              .font(Font.custom("Lato-Regular", size: 15))
              .foregroundColor(viewModel.streamStarted ? Color.neutrals400 : Color.primaryprimary)
              .multilineTextAlignment(.trailing)
          }
          .padding(.horizontal, EkaSpacing.spacingS)
          .padding(.vertical, EkaSpacing.spacingXs)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .stroke(viewModel.streamStarted ? Color.blue : Color.primaryprimary, lineWidth: 1.5)
          )
        }
        .disabled(viewModel.streamStarted)
      }

      if isMultiSelect && !selected.isEmpty {
        Button {
          let combined = selected.sorted().joined(separator: ", ")
          sendMessage(combined)
          selected.removeAll()
        } label: {
          Text("Confirm")
            .font(Font.custom("Lato-Bold", size: 15))
            .foregroundColor(.white)
            .padding(.horizontal, EkaSpacing.spacingM)
            .padding(.vertical, EkaSpacing.spacingXs)
            .background(Color.primaryprimary)
            .clipShape(Capsule())
        }
        .padding(.top, EkaSpacing.spacingXs)
        .disabled(viewModel.streamStarted)
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.trailing, 16)
  }

  private func sendMessage(_ message: String) {
    Task {
      do {
        let lastMessageId = try await DatabaseConfig.shared.fetchLatestMessage(bySessionId: viewModel.vmssid)
        await viewModel.sendMessage(
          newMessage: message,
          imageUrls: nil,
          vaultFiles: nil,
          sessionId: viewModel.vmssid,
          lastMesssageId: lastMessageId
        )
      } catch {
        print("ElicitPillsView: failed to send message: \(error)")
      }
    }
  }
}
