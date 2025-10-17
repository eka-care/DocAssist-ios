//
//  ActiveChatViewWrapper.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 16/10/25.
//

import SwiftUI
import EkaMedicalRecordsCore
import EkaVoiceToRx
import EkaMedicalRecordsUI
import TipKit
import SwiftData

@MainActor
public struct ActiveChatViewWrapper: View {
  @State private var viewModel: ChatViewModel
  @State private var docAssistView: AnyView?
  
  private let backgroundColor: Color?
  private let ctx: ModelContext
  private let patientSubtitle: String?
  private let oid: String
  private let userDocId: String
  private let userBId: String
  private let calledFromPatientContext: Bool
  private let authToken: String
  private let authRefreshToken: String
  private let liveActivityDelegate: LiveActivityDelegate?
  private let userMergedOids: [String]?
  
  public init(
    backgroundColor: Color? = nil,
    ctx: ModelContext,
    patientSubtitle: String?,
    oid: String,
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText,
    calledFromPatientContext: Bool,
    authToken: String,
    authRefreshToken: String,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate,
    liveActivityDelegate: LiveActivityDelegate? = nil,
    suggestionsDelegate: GetMoreSuggestions? = nil,
    userMergedOids: [String]? = nil,
    getPatientDetailsDelegate: GetPatientDetails? = nil,
    openType: String? = nil
  ) {
    self.viewModel = ChatViewModel(
      context: ctx,
      delegate: delegate,
      deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
      liveActivityDelegate: liveActivityDelegate,
      userBid: userBId,
      userDocId: userDocId,
      patientName: patientSubtitle ?? "",
      suggestionsDelegate: suggestionsDelegate,
      getPatientDetailsDelegate: getPatientDetailsDelegate,
      openType: openType
    )
    self.backgroundColor = backgroundColor
    self.ctx = ctx
    self.patientSubtitle = patientSubtitle
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
    self.calledFromPatientContext = calledFromPatientContext
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    self.liveActivityDelegate = liveActivityDelegate
    self.userMergedOids = userMergedOids
  }
  
  public var body: some View {
    Group {
      if let view = docAssistView {
        view
      }
    }
    .onAppear {
      DatabaseConfig.setup(modelContainer: ctx.container)
      MRInitializer.shared.registerCoreSdk(
        authToken: authToken,
        refreshToken: authRefreshToken,
        oid: oid,
        bid: userBId,
        userMergedOids: userMergedOids
      )
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
      
      Task {
        let sessionPresent = await viewModel.isSessionsPresent(oid: oid, userDocId: userDocId, userBId: userBId)
        if calledFromPatientContext, sessionPresent {
          docAssistView = AnyView(
            ExistingPatientChatsView(
              patientName: patientSubtitle ?? "",
              viewModel: viewModel,
              oid: oid,
              userDocId: userDocId,
              userBId: userBId,
              calledFromPatientContext: true,
              authToken: authToken,
              authRefreshToken: authRefreshToken,
              liveActivityDelegate: liveActivityDelegate
            ).navigationBarHidden(true)
              .modelContext(DatabaseConfig.shared.modelContext)
          )
        } else {
          let newSession = await viewModel.createSession(
            subTitle: patientSubtitle,
            oid: oid,
            userDocId: userDocId,
            userBId: userBId
          )
          docAssistView = AnyView(
            ActiveChatView(
              session: newSession,
              viewModel: viewModel,
              backgroundColor: backgroundColor,
              patientName: patientSubtitle ?? "",
              calledFromPatientContext: true,
              userDocId: userDocId,
              userBId: userBId,
              authToken: authToken,
              authRefreshToken: authRefreshToken
            ).navigationBarHidden(true)
              .modelContext(DatabaseConfig.shared.modelContext)
          )
        }
      }
    }
  }
}
