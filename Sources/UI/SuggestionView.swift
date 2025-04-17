//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI

struct SuggestionView: View {
  
  var suggestionText: [String]?
  var viewModel: ChatViewModel
  var lastMessageId: Int?
  
  private var constantSuggestionString = "Suggested questions you can ask me-"
  
  init(suggestionText: [String]?, viewModel: ChatViewModel, lastMessageId: Int? = nil) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
    self.lastMessageId = lastMessageId
  }
  
  var body: some View {
    VStack {
      Text(constantSuggestionString)
        .font(.custom("Lato-Regular", size: 12))
        .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
        .frame(width: 306, height: 16, alignment: .topLeading)
      
      ForEach(suggestionText ?? ["Show HbA1c trend of this patient", "List Lab investigations prescribed in past 1 year", "What are the side effects of the drug Paracetamol?"], id: \.self) { suggestionText in
        Button(action: {
          guard let lastMessageId else { return }
          Task {
            await viewModel.sendMessage(newMessage: suggestionText, imageUrls: nil, vaultFiles: nil, sessionId: viewModel.vmssid, lastMesssageId: lastMessageId)
          }
        }) {
          HStack {
            Text(suggestionText)
              .foregroundColor(Color.primaryprimary)
              .font(.custom("Lato-Regular", size: 14))
              .multilineTextAlignment(.leading)
              .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color.white)
              .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
          }
        }
      }
    }
  }
}
