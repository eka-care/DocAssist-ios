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
  var isMultiSelect: Bool
  
  private var constantSuggestionString = "Suggested questions you can ask me:"
  
  init(
    suggestionText: [String],
    viewModel: ChatViewModel,
    isMultiSelect: Bool = false
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
          isMultiSelect: isMultiSelect
        )
      }
    }
  }
}

struct SuggestionsComponentView: View {
  var suggestionText: [String]
  var viewModel: ChatViewModel
  var isMultiSelect: Bool
  @State private var selectedSuggestions: Set<String> = []
  @State private var selectionOrder: [String] = []
  
  var body: some View {
    VStack(spacing: EkaSpacing.spacingXs) {
      ForEach(suggestionText, id: \.self) { suggestion in
        Button {
          handleTap(on: suggestion)
        } label: {
          HStack {
            Text(suggestion)
              .font(Font.custom("Lato-Regular", size: 16))
              .foregroundColor(foregroundColor(for: suggestion))
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, EkaSpacing.spacingS)
              .padding(.vertical, EkaSpacing.spacingXs)
              .background(backgroundColor(for: suggestion))
              .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer(minLength: 0)
          }
        }
        .disabled(viewModel.streamStarted)
      }
      
      if isMultiSelect, !selectedSuggestions.isEmpty {
        HStack(spacing: EkaSpacing.spacingS) {
          Button("Send selected") {
            sendSelected()
          }
          .buttonStyle(.borderedProminent)
          .disabled(viewModel.streamStarted)
          
          Button("Clear") {
            selectedSuggestions.removeAll()
          }
          .buttonStyle(.bordered)
        }
        .padding(.top, EkaSpacing.spacingXs)
      }
    }
  }
  
  private func handleTap(on suggestion: String) {
    if isMultiSelect {
      toggleSelection(suggestion)
    } else {
      sendSingle(suggestion)
    }
  }
  
  private func toggleSelection(_ suggestion: String) {
    if selectedSuggestions.contains(suggestion) {
      selectedSuggestions.remove(suggestion)
      selectionOrder.removeAll { $0 == suggestion }
    } else {
      selectedSuggestions.insert(suggestion)
      selectionOrder.append(suggestion)
    }
  }
  
  private func sendSingle(_ suggestion: String) {
    Task {
      do {
        let lastMessageId = try await DatabaseConfig.shared.fetchLatestMessage(bySessionId: viewModel.vmssid)
        await viewModel.sendMessage(
          newMessage: suggestion,
          imageUrls: nil,
          vaultFiles: nil,
          sessionId: viewModel.vmssid,
          lastMesssageId: lastMessageId
        )
      } catch {
        print("Error fetching last message id")
      }
    }
  }
  
  private func sendSelected() {
    // Preserve user tap order when building the combined message.
    let selections = selectionOrder
    selectedSuggestions.removeAll()
    selectionOrder.removeAll()
    
    Task {
      do {
        let combined = selections.joined(separator: "\n")
        let lastMessageId = try await DatabaseConfig.shared.fetchLatestMessage(bySessionId: viewModel.vmssid)
        await viewModel.sendMessage(
          newMessage: combined,
          imageUrls: nil,
          vaultFiles: nil,
          sessionId: viewModel.vmssid,
          lastMesssageId: lastMessageId
        )
      } catch {
        print("Error fetching last message id")
      }
    }
  }
  
  private func foregroundColor(for suggestion: String) -> Color {
    if viewModel.streamStarted { return .neutrals400 }
    return selectedSuggestions.contains(suggestion) ? .white : Color.primaryprimary
  }
  
  private func backgroundColor(for suggestion: String) -> Color {
    selectedSuggestions.contains(suggestion) ? Color.primaryprimary : .white
  }
}
