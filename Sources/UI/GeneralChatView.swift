//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI
import SwiftData
import EkaVoiceToRx

public struct GeneralChatView: View {
  
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  var delegate: ConvertVoiceToText
  var userDocId: String
  var userBId: String
  var patientDelegate: NavigateToPatientDirectory
  var searchForPatient: (() -> Void)
  var authToken: String
  var authRefreshToken: String
  @Binding var selectedScreen: SelectedScreen?
  var deepThoughtNavigationDelegate: DeepThoughtsViewDelegate
  var liveActivityDelegate: LiveActivityDelegate?
  
  public init(
    backgroundColor: Color? = .white,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext,
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText,
    patientDelegate: NavigateToPatientDirectory,
    searchForPatient: @escaping (() -> Void),
    authToken: String,
    authRefreshToken: String,
    selectedScreen: Binding<SelectedScreen?>,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate,
    liveActivityDelegate: LiveActivityDelegate? = nil
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
    _selectedScreen = selectedScreen
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.liveActivityDelegate = liveActivityDelegate
  }
  
  public var body: some View {
    ChatsScreenView(
      backgroundColor: backgroundColor,
      subTitle: subTitle,
      userDocId: userDocId,
      userBid: userBId,
      ctx: ctx,
      delegate: delegate,
      patientDelegate: patientDelegate,
      searchForPatient: searchForPatient,
      authToken: authToken,
      authRefreshToken: authRefreshToken,
      selectedScreen: $selectedScreen,
      deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
      liveActivityDelegate: liveActivityDelegate
    )
    .modelContext(DatabaseConfig.shared.modelContainer.mainContext)
    .navigationBarHidden(true)
  }
}
