//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI
import SwiftData

public struct GeneralChatView: View {
  
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  var userDocId: String
  var userBId: String
  var patientDelegate: NavigateToPatientDirectory?
  var searchForPatient: (() -> Void)?
  var authToken: String
  var authRefreshToken: String
  @Binding var selectedScreen: SelectedScreen?
  var suggestionsDelegate: GetMoreSuggestions? = nil
  var getPatientDetailsDelegate: GetPatientDetails?
  
  public init(
    backgroundColor: Color? = .white,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext,
    userDocId: String,
    userBId: String,
    patientDelegate: NavigateToPatientDirectory?,
    searchForPatient: (() -> Void)?,
    authToken: String,
    authRefreshToken: String,
    selectedScreen: Binding<SelectedScreen?>,
    suggestionsDelegate: GetMoreSuggestions? = nil,
    getPatientDetailsDelegate: GetPatientDetails? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.ctx = ctx
    self.userDocId = userDocId
    self.userBId = userBId
    self.patientDelegate = patientDelegate
    self.searchForPatient = searchForPatient
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    _selectedScreen = selectedScreen
    self.getPatientDetailsDelegate = getPatientDetailsDelegate
  }
  
  public var body: some View {
    ChatsScreenView(
      backgroundColor: backgroundColor,
      subTitle: subTitle,
      userDocId: userDocId,
      userBid: userBId,
      ctx: ctx,
      patientDelegate: patientDelegate,
      searchForPatient: searchForPatient,
      authToken: authToken,
      authRefreshToken: authRefreshToken,
      selectedScreen: $selectedScreen,
      getPatientDetailsDelegate: getPatientDetailsDelegate
    )
    .modelContext(DatabaseConfig.shared.modelContainer.mainContext)
  }
}
