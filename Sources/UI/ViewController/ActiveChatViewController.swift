//
//  ActiveChatViewController.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 18/06/25.
//

import UIKit
import SwiftUI
import SwiftData
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore
import EkaVoiceToRx
import TipKit

public class ActiveChatViewController: UIViewController {
  
  private let backgroundColor: Color?
  private let ctx: ModelContext
  private let patientSubtitle: String?
  private let oid: String
  private let userDocId: String
  private let userBId: String
  private let calledFromPatientContext: Bool
  private let authToken: String
  private let authRefreshToken: String
  var userMergedOids: [String]?
  
  var docAssistView: AnyView?
  var vm: ChatViewModel
  var liveActivityDelegate: LiveActivityDelegate?
  var suggestionsDelegae: GetMoreSuggestions?
  var getPatientDetailsDelegate: GetPatientDetails?
    
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
    getPatientDetailsDelegate: GetPatientDetails? = nil
  ) {
    self.vm = ChatViewModel(
      context: ctx,
      delegate: delegate,
      deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
      liveActivityDelegate: liveActivityDelegate,
      userBid: userBId,
      userDocId: userDocId,
      patientName: patientSubtitle ?? "",
      suggestionsDelegate: suggestionsDelegate,
      getPatientDetailsDelegate: getPatientDetailsDelegate
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
    
    super.init(nibName: nil, bundle: nil)
 //   registerUISdk()
    registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId, userDocId: userDocId, userMergeOids: userMergedOids)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    setupSubViews()
    DatabaseConfig.setup(modelContainer: ctx.container)
    DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
  }
  
  private func setupSwiftUIView() async {
    let sessionPresent = await vm.isSessionsPresent(oid: oid, userDocId: userDocId, userBId: userBId)
    if calledFromPatientContext, sessionPresent {
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
        )
        .navigationBarHidden(true)
        .task {
            try? Tips.configure([
                .displayFrequency(.daily),
                .datastoreLocation(.applicationDefault)
            ])
        }
      docAssistView = AnyView(existingChatsView.modelContext( DatabaseConfig.shared.modelContext))
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
        )
        .navigationBarHidden(true)
        .task {
            try? Tips.configure([
            .displayFrequency(.daily),
            .datastoreLocation(.applicationDefault)
            ])
        }
      docAssistView = await AnyView(activeChatView.modelContext( DatabaseConfig.shared.modelContext))
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
    }
  }
  
  override public func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      self.navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  private func setupSubViews() {
    Task {
      await setupSwiftUIView()
      
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        let uiHostingViewController = UIHostingController(rootView: docAssistView)
        
        addChild(uiHostingViewController)
        view.addSubview(uiHostingViewController.view)
        
        uiHostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          uiHostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
          uiHostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          uiHostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          uiHostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
      }
    }
  }
}

extension ActiveChatViewController {
  func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String, userDocId: String, userMergeOids: [String]?) {
    MRInitializer.shared
      .registerCoreSdk(
        authToken: authToken,
        refreshToken: refreshToken,
        oid: oid,
        bid: bid,
        userMergedOids: userMergedOids
      )
  }
}
