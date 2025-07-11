//
//  IpadDetailChatView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 12/02/25.
//

import SwiftUI

struct IpadDetailChatView: View {
  
  let selectedScreen: SelectedScreen?
  let authToken: String
  let authRefreshToken: String
  
    var body: some View {
      VStack {
        switch selectedScreen {
        case .selectedPatient(let chatViewModel, let oid, let userDocId, let userBId, let patientName) :
          ExistingPatientChatsView(
            patientName: patientName,
            viewModel: chatViewModel,
            oid: oid ,
            userDocId: userDocId,
            userBId: userBId,
            calledFromPatientContext: false,
            authToken: authToken,
            authRefreshToken: authRefreshToken
          )
          .modelContext( DatabaseConfig.shared.modelContext)
        case .allPatient(let selectedPatient, let chatViewModel, let userDocId, let userBId) :
          ActiveChatView(session: selectedPatient.sessionId, viewModel: chatViewModel, backgroundColor: .white, patientName: selectedPatient.subTitle ?? "empty User", calledFromPatientContext: false, title: selectedPatient.title, userDocId: userDocId, userBId: userBId, authToken: authToken, authRefreshToken: authRefreshToken)
            .modelContext( DatabaseConfig.shared.modelContext)
        default:
          DetailEmptyView()
        }
      }
    }
}


