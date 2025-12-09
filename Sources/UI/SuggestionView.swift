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
