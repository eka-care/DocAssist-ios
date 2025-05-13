//
//  DocAssistChatWrapperView.swift
//  DocAssist-ios
//
//  Created by Brunda B on 07/05/25.
//

import SwiftUI
import SwiftData
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore
import EkaVoiceToRx

public struct DocAssistChatWrapperView: View {
  let backgroundColor: Color?
  let emptyMessageColor: Color?
  let editButtonColor: Color?
  let subTitle: String?
  let ctx: ModelContext
  let userDocId: String
  let userBId: String
  let delegate: ConvertVoiceToText?
  let patientDelegate: NavigateToPatientDirectory?
  let authToken: String
  let authRefreshToken: String
  let deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?
  
  public init(
    backgroundColor: Color?,
    emptyMessageColor: Color?,
    editButtonColor: Color?,
    subTitle: String?,
    ctx: ModelContext,
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText?,
    patientDelegate: NavigateToPatientDirectory?,
    authToken: String,
    authRefreshToken: String,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?
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
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
  }
  
  public var body: some View {
    Group {
      if UIDevice.current.userInterfaceIdiom == .pad {
        IpadChatView(
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
          deepThoughtNavigationDelegate: deepThoughtNavigationDelegate
        ).modelContext(ctx)
      } else {
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
          selectedScreen: .constant(nil),
          deepThoughtNavigationDelegate: deepThoughtNavigationDelegate
        ).modelContext(ctx)
      }
    }
  }
  
  func searchForPatient() {
    patientDelegate?.navigateToPatientDirectory()
  }
}

public struct ActiveChatWrapperView: View {
  let backgroundColor: Color?
  let ctx: ModelContext
  let patientSubtitle: String?
  private let oid: String
  private let userDocId: String
  private let userBId: String
  private let calledFromPatientContext: Bool
  private let authToken: String
  let authRefreshToken: String
  var vm: ChatViewModel
  let delegate: ConvertVoiceToText?
  var liveActivityDelegate: LiveActivityDelegate?
  @State private var activeView: AnyView?
  
  public init(
    backgroundColor: Color?,
    ctx: ModelContext,
    patientSubtitle: String?,
    oid: String,
    userDocId: String,
    userBId: String,
    calledFromPatientContext: Bool,
    authToken: String,
    authRefreshToken: String,
    delegate: ConvertVoiceToText?,
    liveActivityDelegate: LiveActivityDelegate? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.ctx = ctx
    self.patientSubtitle = patientSubtitle
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
    self.calledFromPatientContext = calledFromPatientContext
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    self.vm = ChatViewModel(
      context: ctx,
      delegate: delegate,
      liveActivityDelegate: liveActivityDelegate,
      userBid: userBId,
      userDocId: userDocId,
      patientName: patientSubtitle ?? ""
    )
    self.delegate = delegate
    self.liveActivityDelegate = liveActivityDelegate
  }
  
  public var body: some View {
    Group {
      if let activeView = activeView {
        activeView
      } else {
        ProgressView()
      }
    }
    .onAppear {
      Task {
        let sessionPresent = await vm.isSessionsPresent(oid: oid, userDocId: userDocId, userBId: userBId)
        if sessionPresent {
          let existingChatsView = ExistingPatientChatsView(
            patientName: patientSubtitle ?? "",
            viewModel: vm,
            oid: oid,
            userDocId: userDocId,
            userBId: userBId,
            calledFromPatientContext: true,
            authToken: authToken,
            authRefreshToken: authRefreshToken,
            liveActivityDelegate: liveActivityDelegate
          ).navigationBarHidden(true)
          self.activeView = AnyView(existingChatsView.modelContext(DatabaseConfig.shared.modelContext))
        } else {
          let newSession = await vm.createSession(subTitle: patientSubtitle, oid: oid, userDocId: userDocId, userBId: userBId)
          let activeChatView = ActiveChatView(
            session: newSession,
            viewModel: vm,
            backgroundColor: backgroundColor,
            patientName: patientSubtitle ?? "",
            calledFromPatientContext: true,
            userDocId: userDocId,
            userBId: userBId,
            authToken: authToken,
            authRefreshToken: authRefreshToken
          ).navigationBarHidden(true)
          self.activeView = AnyView(activeChatView.modelContext(DatabaseConfig.shared.modelContext))
          DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
        }
      }
    }
  }
}

private func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String, userDocId: String) {
    var ownerId: String = oid
    if oid.isEmpty {
        ownerId = userDocId
    }
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.filterID = ownerId
    CoreInitConfigurations.shared.ownerID = bid
}
