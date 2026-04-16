//
//  SuggestionsComponentView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 08/12/25.
//
import SwiftUI
import EkaUI

struct SuggestionsComponentView: View {
  var suggestionText: [String]
  var viewModel: ChatViewModel
  var isMultiSelect: Bool = false
  /// When false, chips are non-tappable and styled as disabled (e.g. suggestions from earlier bot turns).
  var isInteractive: Bool = true
  
  @State private var selectedSuggestions: Set<String> = []
  
  private var suggestionsEnabled: Bool {
    isInteractive && !viewModel.streamStarted
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: EkaSpacing.spacingXs) {
      ForEach(suggestionText, id: \.self) { suggestion in
        Button {
          if isMultiSelect {
            if selectedSuggestions.contains(suggestion) {
              selectedSuggestions.remove(suggestion)
            } else {
              selectedSuggestions.insert(suggestion)
            }
          } else {
            sendMessage(suggestion)
          }
        } label: {
          HStack(spacing: EkaSpacing.spacingXs) {
            if isMultiSelect {
              Image(systemName: selectedSuggestions.contains(suggestion) ? "checkmark.square.fill" : "square")
                .foregroundColor(selectedSuggestions.contains(suggestion) ? Color(red: 0.42, green: 0.36, blue: 0.878) : Color.neutrals400)
                .font(.system(size: 20))
            }
            
            Text(suggestion)
              .font(.system(size: 16))
              .foregroundColor(suggestionsEnabled ? Color(red: 0.42, green: 0.36, blue: 0.878) : Color.neutrals400)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
          }
          .padding(.horizontal, EkaSpacing.spacingS)
          .padding(.vertical, EkaSpacing.spacingXs)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          //          .overlay(
          //            RoundedRectangle(cornerRadius: 12)
          //              .stroke(isMultiSelect && selectedSuggestions.contains(suggestion) ? Color.primaryprimary : Color.clear, lineWidth: 2)
          //          )
        }
        .disabled(!suggestionsEnabled)
      }
      
      if isMultiSelect && !selectedSuggestions.isEmpty {
        Button {
          let combinedMessage = Array(selectedSuggestions).joined(separator: ", ")
          sendMessage(combinedMessage)
          selectedSuggestions.removeAll()
        } label: {
          Text("Confirm")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, EkaSpacing.spacingS)
            .background(Color(red: 0.42, green: 0.36, blue: 0.878))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, EkaSpacing.spacingXs)
        .disabled(!suggestionsEnabled)
      }
    }
  }
  
  private func sendMessage(_ message: String) {
    Task { @MainActor in
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
        print("Error fetching last message id: \(error)")
      }
    }
  }
}
