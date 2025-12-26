//
//  ActiveChatViewWrapper.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 16/10/25.
//

import SwiftUI
import EkaMedicalRecordsCore
import EkaMedicalRecordsUI
import SwiftData

/// Todo: - session handling
@MainActor
public struct ActiveChatViewWrapper: View {
  @State private var sessionPresent: Bool? = nil
  @State private var newSession: String? = nil
  @State private var didCheckSession = false
  
  private let backgroundColor: Color?
  private let ctx: ModelContext
  private let patientSubtitle: String?
  private let oid: String
  private let userDocId: String
  private let userBId: String
  private let calledFromPatientContext: Bool
  private let authToken: String
  private let authRefreshToken: String
  private let userMergedOids: [String]?
  
  private let viewModel: ChatViewModel
  
  public init(
    backgroundColor: Color? = nil,
    ctx: ModelContext,
    patientSubtitle: String?,
    oid: String,
    userDocId: String,
    userBId: String,
    calledFromPatientContext: Bool,
    authToken: String,
    authRefreshToken: String,
    userMergedOids: [String]? = nil,
    getPatientDetailsDelegate: GetPatientDetails? = nil,
    openType: String? = nil
  ) {
    self.viewModel = ChatViewModel(
      context: ctx,
      userBid: userBId,
      userDocId: userDocId,
      patientName: patientSubtitle ?? "",
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
    self.userMergedOids = userMergedOids
  }
  
  public var body: some View {
    Group {
      if let sessionPresent {
        if calledFromPatientContext, sessionPresent {
          ExistingPatientChatsView(
            patientName: patientSubtitle ?? "",
            viewModel: viewModel,
            oid: oid,
            userDocId: userDocId,
            userBId: userBId,
            calledFromPatientContext: true,
            authToken: authToken,
            authRefreshToken: authRefreshToken,
            useNavigationStack: false
          )
          .modelContext(DatabaseConfig.shared.modelContext)
        } else if let sessionId = newSession {
          ActiveChatView(
            session: sessionId,
            viewModel: viewModel,
            backgroundColor: backgroundColor,
            patientName: patientSubtitle ?? "",
            calledFromPatientContext: false,
            userDocId: userDocId,
            userBId: userBId,
            authToken: authToken,
            authRefreshToken: authRefreshToken
          )
          .modelContext(DatabaseConfig.shared.modelContext)
        } else {
          ProgressView("Loading chat…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      } else {
        ProgressView("Checking chat session…")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        let present = await viewModel.isSessionsPresent(oid: oid, userDocId: userDocId, userBId: userBId)
        sessionPresent = present
        
        if !present || !calledFromPatientContext {
          let sessionId = await viewModel.createSession(
            subTitle: patientSubtitle,
            oid: oid,
            userDocId: userDocId,
            userBId: userBId
          )
          newSession = sessionId
        }
      }
    }
  }
}
