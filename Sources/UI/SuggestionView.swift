//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI
import EkaUI

struct SuggestionView: View {
  
  var suggestionText: [String]
  var viewModel: ChatViewModel
  var isMultiSelect: Bool? = nil
  
  private var constantSuggestionString = "Suggested questions you can ask me:"
  
  init(
    suggestionText: [String],
    viewModel: ChatViewModel,
    isMultiSelect: Bool
  ) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
    self.isMultiSelect = isMultiSelect
  }
  
  var body: some View {
    HStack(alignment: .top) {
      BotAvatarImage()
      VStack(alignment: .leading) {
        Text(constantSuggestionString)
          .font(.custom("Lato-Regular", size: 12))
          .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
          .frame(width: 306, height: 16, alignment: .topLeading)
        SuggestionsComponentView(
          suggestionText: suggestionText,
          viewModel: viewModel,
          isMultiSelect: isMultiSelect ?? false
        )
      }
    }
  }
}

struct SuggestionsComponentView: View {
  var suggestionText: [String]
  var viewModel: ChatViewModel
  var isMultiSelect: Bool = false
  
  @State private var selectedSuggestions: Set<String> = []
  
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
                .foregroundColor(selectedSuggestions.contains(suggestion) ? Color.primaryprimary : Color.neutrals400)
                .font(.system(size: 20))
            }
            
            Text(suggestion)
              .font(Font.custom("Lato-Regular", size: 16))
              .foregroundColor(viewModel.streamStarted ? Color.neutrals400 : Color.primaryprimary)
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
        .disabled(viewModel.streamStarted)
      }
      
      if isMultiSelect && !selectedSuggestions.isEmpty {
        Button {
          let combinedMessage = Array(selectedSuggestions).joined(separator: ", ")
          sendMessage(combinedMessage)
          selectedSuggestions.removeAll()
        } label: {
          Text("Confirm")
            .font(Font.custom("Lato-Bold", size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, EkaSpacing.spacingS)
            .background(Color.primaryprimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, EkaSpacing.spacingXs)
        .disabled(viewModel.streamStarted)
      }
    }
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
        print("Error fetching last message id: \(error)")
      }
    }
  }
}
