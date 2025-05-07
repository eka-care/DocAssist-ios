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
    let liveActivityDelegate: LiveActivityDelegate?
    let deviceType: String?
    
  init(backgroundColor: Color?, emptyMessageColor: Color?, editButtonColor: Color?, subTitle: String?, ctx: ModelContext, userDocId: String, userBId: String, delegate: ConvertVoiceToText?, patientDelegate: NavigateToPatientDirectory?, authToken: String, authRefreshToken: String, deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?, liveActivityDelegate: LiveActivityDelegate?, deviceType: String?) {
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
    self.liveActivityDelegate = liveActivityDelegate
    self.deviceType = deviceType
  }
  
    public var body: some View {
        Group {
            if deviceType?.lowercased() == "ipad" {
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
                    deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
                    liveActivityDelegate: liveActivityDelegate
                ).modelContext(ctx)
            }
        }
    }

   func searchForPatient() {
        patientDelegate?.navigateToPatientDirectory()
    }
}

public struct ActiveChatWrapperView: View {
    let ctx: ModelContext
    let backgroundColor: Color?
    let patientSubtitle: String?
    let oid: String
    let userDocId: String
    let userBId: String
    let delegate: ConvertVoiceToText?
    let calledFromPatientContext: Bool
    let authToken: String
    let authRefreshToken: String
    let deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?
    let liveCActivityDelegate: LiveActivityDelegate?

    @State private var viewModel: ChatViewModel
     @State private var session: String?
    @State private var isLoading = true

    public init(
        ctx: ModelContext,
        backgroundColor: Color? = nil,
        patientSubtitle: String? = nil,
        oid: String,
        userDocId: String,
        userBId: String,
        delegate: ConvertVoiceToText,
        calledFromPatientContext: Bool,
        authToken: String,
        authRefreshToken: String,
        deepThoughtNavigationDelegate: DeepThoughtsViewDelegate,
        liveActivityDelegate: LiveActivityDelegate? = nil
    ) {
        self.ctx = ctx
        self.backgroundColor = backgroundColor
        self.patientSubtitle = patientSubtitle
        self.oid = oid
        self.userDocId = userDocId
        self.userBId = userBId
        self.delegate = delegate
        self.calledFromPatientContext = calledFromPatientContext
        self.authToken = authToken
        self.authRefreshToken = authRefreshToken
        self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
        self.liveActivityDelegate = liveActivityDelegate
        _viewModel = State(initialValue: ChatViewModel(
            context: ctx,
            delegate: delegate,
            deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
            liveActivityDelegate: liveActivityDelegate,
            userBid: userBId,
            userDocId: userDocId,
            patientName: patientSubtitle ?? ""
        ))
      registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId, userDocId: StringuserDocId)
      registerAuthToken(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId)
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .onAppear {
                        Task {
                            let sessionPresent = await viewModel.isSessionsPresent(
                                oid: oid,
                                userDocId: userDocId,
                                userBId: userBId
                            )

                            if calledFromPatientContext, sessionPresent {
                                // no need to create session
                            } else {
                                session = await viewModel.createSession(
                                    subTitle: patientSubtitle,
                                    oid: oid,
                                    userDocId: userDocId,
                                    userBId: userBId
                                )
                            }
                            isLoading = false
                        }
                    }
            } else {
                if calledFromPatientContext, session == nil {
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
                    ).modelContext(ctx)
                } else if let session = session {
                    ActiveChatView(
                        session: session,
                        viewModel: viewModel,
                        backgroundColor: backgroundColor,
                        patientName: patientSubtitle ?? "",
                        calledFromPatientContext: true,
                        userDocId: userDocId,
                        userBId: userBId,
                        authToken: authToken,
                        authRefreshToken: authRefreshToken
                    ).modelContext(ctx)
                }
            }
        }
    }
  
  func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String, userDocId: String) {
    var ownerId: String = oid
    if oid.isEmpty {
      ownerId = userDocId
    }
    registerAuthToken(authToken: authToken, refreshToken: refreshToken, oid: ownerId, bid: bid)
  }
  
  private func registerAuthToken(authToken: String, refreshToken: String, oid: String, bid: String) {
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.filterID = oid
    CoreInitConfigurations.shared.ownerID = bid
  }
}
