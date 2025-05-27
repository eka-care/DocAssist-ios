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
    
    private var constantSuggestionString = "Suggested questions you can ask me-"
    
    init(suggestionText: [String], viewModel: ChatViewModel) {
        self.suggestionText = suggestionText
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        HStack(alignment: .top) {
            BotAvatarImage()
            VStack(alignment: .leading) {
                Text(constantSuggestionString)
                    .font(.custom("Lato-Regular", size: 12))
                    .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                    .frame(width: 306, height: 16, alignment: .topLeading)
                ForEach(suggestionText, id: \.self) { suggestionText in
                    Button {
                        Task {
                            do {
                                let lastMessageId = try await DatabaseConfig.shared.fetchLatestMessage(bySessionId: viewModel.vmssid)
                                await viewModel.sendMessage(newMessage: suggestionText, imageUrls: nil, vaultFiles: nil, sessionId: viewModel.vmssid, lastMesssageId: lastMessageId)
                            } catch {
                                print("Error fetching last message id")
                            }
                        }
                    } label: {
                        HStack {
                            Text(suggestionText)
                                .font(Font.custom("Lato-Regular", size: 14))
                                .foregroundColor(viewModel.streamStarted ? Color.neutrals400 : Color.primaryprimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, EkaSpacing.spacingS)
                                .padding(.vertical, EkaSpacing.spacingXs)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                    }
                    .disabled(viewModel.streamStarted)
                }
            }
            
        }
    }
}

