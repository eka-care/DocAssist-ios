//
//  ExistingPatientChatsView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 23/01/25.
//

import SwiftUI

public struct ExistingPatientChatsView: View {
  @State var patientName: String
  @State private var navigateToActiveChatView: Bool = false
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundColor: Color?
  var oid: String
  var userDocId: String
  var userBId: String
  @State var session: ExistingChatResponse?
  @Environment(\.dismiss) var dismiss
  
  init(patientName: String, viewModel: ChatViewModel, backgroundColor: Color? = nil, oid: String, userDocId: String, userBId: String) {
    self.patientName = patientName
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
  }
  
  public var body: some View {
    NavigationStack {
      list
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
          Button {
          session = viewModel.createSession(subTitle: patientName, oid: oid, userDocId: userDocId, userBId: userBId)
          navigateToActiveChatView = true
          }
          label: {
            Text("New chat")
              .foregroundStyle(Color.primaryprimary)
          }
        }
        .navigationTitle(patientName)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToActiveChatView) {
          ActiveChatView(
            session: session?.sessionId.first ?? "dsasdfsdafasdfsad",
            viewModel: viewModel,
            backgroundColor: backgroundColor,
            patientName: patientName,
            calledFromPatientContext: false)
          
        }
    }
  }
  var list: some View {
    ScrollView {
      VStack {
        VStack {
          HStack() {
            Text("Medical Document")
              .font(Font.custom("Lato-Regular", size: 14))
              .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
              .padding(.leading, 16)
            Spacer()
          }
          Button {
            
          } label: {
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 4) {
                
                Image(.fileWaveForm)
                  .padding(6)
                  .background(Color(red: 0.46, green: 0.46, blue: 0.46))
                  .cornerRadius(6)
                
                Text("Medical documents")
                  .font(Font.custom("Lato-Regular", size: 16))
                  .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                  .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                  Text("32")
                    .font(Font.custom("Lato-Regular", size: 16))
                    .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
                  
                  Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                }
                .padding(.trailing, 16)
              }
              .padding(.horizontal, 16)
              .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
            }
            .background(Color.white)
            .cornerRadius(8)
          }
        }
        .padding(.bottom, 5)
        
        HStack {
          Text("5 chats found")
            .font(Font.custom("Lato-Regular", size: 14))
            .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            .padding(.leading, 16)
          Spacer()
        }
        
        Button {
          
        } label: {
          VStack(spacing: 0) {
            ChatRow(
              title: "Vital trends",
              subtitle: "Chat",
              time: "2m ago"
            )
            
            Divider()
              .padding(.leading, 56)
            
            ChatRow(
              title: "Vital trends",
              subtitle: "Chat",
              time: "2m ago"
            )
            
            Divider()
              .padding(.leading, 56)
            
            ChatRow(
              title: "Vital trends",
              subtitle: "Chat",
              time: "2m ago"
            )
            
            Divider()
              .padding(.leading, 56)
            
            ChatRow(
              title: "Vital trends",
              subtitle: "Chat",
              time: "2m ago"
            )
            
          }
          .background(Color.white)
          .cornerRadius(12)
        }
      }
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
  }
}

