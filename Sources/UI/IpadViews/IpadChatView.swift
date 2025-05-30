//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 08/12/24.
//

import SwiftUI
import SwiftData
import TipKit

public enum SelectedScreen {
  case selectedPatient(ChatViewModel, String, String, String, String)
  case allPatient(SessionDataModel, ChatViewModel, String, String)
  case emptyScreen
}

public struct IpadChatView: View {
  
  @State private var splitViewColumnVisibility: NavigationSplitViewVisibility = .doubleColumn
  @State private var selectedScreen: SelectedScreen? = .emptyScreen
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  var delegate: ConvertVoiceToText?
  var userDocId: String
  var userBId: String
  var patientDelegate: NavigateToPatientDirectory?
  var searchForPatient: (()->Void)
  var authToken: String
  var authRefreshToken: String
  var deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?
  var suggestionsDelegate: GetMoreSuggestions?
  
  public init(
    backgroundColor: Color? = nil,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext,
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText?,
    patientDelegate: NavigateToPatientDirectory?,
    searchForPatient: @escaping (()->Void),
    authToken: String,
    authRefreshToken: String,
    selectedScreen: SelectedScreen? = .emptyScreen,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?,
    suggestionsDelegate: GetMoreSuggestions? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.ctx = ctx
    self.userDocId = userDocId
    self.userBId = userBId
    self.delegate = delegate
    self.patientDelegate = patientDelegate
    self.searchForPatient = searchForPatient
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    self.selectedScreen = selectedScreen
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.suggestionsDelegate = suggestionsDelegate
  }
  
  public var body: some View {
    NavigationSplitView(columnVisibility: $splitViewColumnVisibility) {
      GeneralChatView(
        backgroundColor: backgroundColor,
        emptyMessageColor: emptyMessageColor,
        editButtonColor: editButtonColor,
        subTitle: subTitle,
        ctx: ctx,
        userDocId: userDocId,
        userBId: userBId,
        delegate: delegate,
        patientDelegate: patientDelegate,
        searchForPatient: searchForPatient,
        authToken: authToken,
        authRefreshToken: authRefreshToken,
        selectedScreen: $selectedScreen,
        deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
        suggestionsDelegate: suggestionsDelegate
      )
      .modelContext( DatabaseConfig.shared.modelContext)
    } detail: {
      IpadDetailChatView(
        selectedScreen: selectedScreen,
        authToken: authToken,
        authRefreshToken: authRefreshToken
      )
      .modelContext( DatabaseConfig.shared.modelContext)
    }
    .navigationSplitViewStyle(.balanced)
    .task {
        try? Tips.resetDatastore()
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
  }
  
}



