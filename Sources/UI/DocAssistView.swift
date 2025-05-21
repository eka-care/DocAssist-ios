//
//  DocAssistView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 14/02/25.
//

import SwiftUI

enum DocAssistScreen {
  case calledFromPatientForFirstTime
  case existingPatient
  case allChats
}

struct DocAssistView: View {
  
  let screen: DocAssistScreen
  
  var body: some View {
    VStack {
      switch screen {
      case .calledFromPatientForFirstTime :
        Text("Called from Patient")
        
          //ActiveChatsView(userDocId: <#T##String#>, userBid: <#T##String#>, ctx: <#T##ModelContext#>, delegate: <#T##any ConvertVoiceToText#>, patientDelegate: <#T##any NavigateToPatientDirectory#>, searchForPatient: <#T##(() -> Void)##(() -> Void)##() -> Void#>, authToken: <#T##String#>, authRefreshToken: <#T##String#>, selectedScreen: <#T##Binding<SelectedScreen?>#>)
      case .existingPatient :
        Text("Called from Patient")
        //ExistingPatientChatsView()
      case .allChats :
        Text("All Chats")
   //     ChatListView(userDocId: <#T##String#>, userBid: <#T##String#>, ctx: <#T##ModelContext#>, delegate: <#T##any ConvertVoiceToText#>, patientDelegate: <#T##any NavigateToPatientDirectory#>, searchForPatient: <#T##(() -> Void)##(() -> Void)##() -> Void#>, authToken: <#T##String#>, authRefreshToken: <#T##String#>, selectedScreen: <#T##Binding<SelectedScreen?>#>)
        
      }
    }
  }
}

