//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI

struct SuggestionView: View {
  
  var suggestionText: String = ""
  var viewModel: ChatViewModel
  
  init(suggestionText: String, viewModel: ChatViewModel) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
  }
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .frame(width: 360, height: 40)
        .foregroundStyle(Color.nuetralWhite)
      Button(action: {
        viewModel.sendMessage(newMessage: suggestionText)
      }) {
        HStack {
          Text(suggestionText)
            .foregroundColor(Color.primaryprimary)
            .lineLimit(1)
            .padding(.leading, 10)
          Spacer()
        }
      }
    }
    .frame(width: 360, height: 40)
  }
}

