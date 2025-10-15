//
//  ChatsViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI
import SwiftData
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore
import EkaVoiceToRx
import TipKit

public class ChatsViewController: UIViewController {
  private var docAssistView: UIView!
  private var uiHostingController: UIHostingController<AnyView>!
  private var patientDelegate: NavigateToPatientDirectory?
  let ctx: ModelContext
  var liveActivityDelegate: LiveActivityDelegate?
  var suggestionsDelegate: GetMoreSuggestions?
  var userMergedOids: [String]?
  var getPatientDetailsDelegate: GetPatientDetails?
  
  public init(
    backgroundColor: Color? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    subTitle: String? = nil,
    ctx: ModelContext,
    deviceType: String? = "phone",
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText?,
    patientDelegate: NavigateToPatientDirectory?,
    authToken: String,
    authRefreshToken: String,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?,
    liveActivityDelegate: LiveActivityDelegate? = nil,
    suggestionsDelegate: GetMoreSuggestions? = nil,
    userMergedOids: [String]? = nil,
    getPatientDetailsDelegate: GetPatientDetails?
  ) {
    self.patientDelegate = patientDelegate
    self.ctx = ctx
    self.liveActivityDelegate = liveActivityDelegate
    self.userMergedOids = userMergedOids
    super.init(nibName: nil, bundle: nil)
    switch deviceType?.lowercased() {
    case "ipad":
      let ipadView = IpadChatView(
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
        deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
        suggestionsDelegate: suggestionsDelegate,
        getPatientDetailsDelegate: getPatientDetailsDelegate
      )
            .task {
                try? Tips.configure([
                    .displayFrequency(.daily),
                    .datastoreLocation(.applicationDefault)
                ])
            }
      uiHostingController = UIHostingController(rootView: AnyView(ipadView))
      
    default:
      let iphoneView = GeneralChatView(
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
        selectedScreen: Binding.constant(nil),
        deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
        liveActivityDelegate: liveActivityDelegate,
        suggestionsDelegate: suggestionsDelegate,
        getPatientDetailsDelegate: getPatientDetailsDelegate
      )
            .task {
                try? Tips.configure([
                    .displayFrequency(.daily),
                    .datastoreLocation(.applicationDefault)
                ])
            }
      uiHostingController = UIHostingController(rootView: AnyView(iphoneView))
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let uiHostingController = uiHostingController else { return }
    
    addChild(uiHostingController)
    view.addSubview(uiHostingController.view)
    
    uiHostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      uiHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      uiHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      uiHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      uiHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    
    uiHostingController.didMove(toParent: self)
    
    DatabaseConfig.setup(modelContainer: ctx.container)
    DocAssistEventManager.shared.trackEvent(event: .docAssistHistoryPage, properties: ["type": "overall"])
  }
  
  override public func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      self.navigationController?.setNavigationBarHidden(false, animated: false)
  }
  
  private func searchForPatient() {
    patientDelegate?.navigateToPatientDirectory()
  }
}

extension ChatsViewController {
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
