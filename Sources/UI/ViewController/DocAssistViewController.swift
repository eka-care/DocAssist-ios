//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI
import SwiftData
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore

public class DocAssistViewController: UIViewController {
  private var docAssistView: UIView!
  private var uiHostingController: UIHostingController<AnyView>!
  private var patientDelegate: NavigateToPatientDirectory
  public init(
    backgroundColor: Color? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    subTitle: String? = nil,
    ctx: ModelContext,
    deviceType: String? = "phone",
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText,
    patientDelegate: NavigateToPatientDirectory,
    authToken: String,
    authRefreshToken: String
    
  ) {
    self.patientDelegate = patientDelegate
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
        authRefreshToken: authRefreshToken
      )
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
        authRefreshToken: authRefreshToken
        
      )
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
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  private func searchForPatient() {
    patientDelegate.navigateToPatientDirectory()
  }
}

public class ActiveChatViewController: UIViewController {
  
  var docAssistView: AnyView
  var vm: ChatViewModel
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
    authRefreshToken: String
  ) {
    vm = ChatViewModel(context: ctx, delegate: delegate)
    let sessionPresent = vm.isSessionsPresent(oid: oid, userDocId: userDocId, userBId: userBId)
    if calledFromPatientContext, sessionPresent {
        let existingChatsView = ExistingPatientChatsView(
            patientName: patientSubtitle ?? "",
            viewModel: vm,
            oid: oid,
            userDocId: userDocId,
            userBId: userBId,
            calledFromPatientContext: true,
            authToken: authToken,
            authRefreshToken: authRefreshToken
        )
        docAssistView = AnyView(existingChatsView.modelContext(ctx))
    } else {
        let newSession = vm.createSession(subTitle: patientSubtitle, oid: oid, userDocId: userDocId, userBId: userBId)
        let activeChatView = ActiveChatView(
            session: newSession,
            viewModel: vm,
            backgroundColor: backgroundColor,
            patientName: patientSubtitle ?? "",
            calledFromPatientContext: true
        )
        docAssistView = AnyView(activeChatView.modelContext(ctx))
    }
    super.init(nibName: nil, bundle: nil)
    registerUISdk()
    registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId, userDocId: userDocId)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
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
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }
}

extension ActiveChatViewController {
  
  func registerUISdk() {
    registerFonts()
  }
  
  private func registerFonts() {
    do {
      try Fonts.registerAllFonts()
    } catch {
      debugPrint("Failed to fetch fonts")
    }
  }
  
  func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String, userDocId: String) {
    var ownerId: String = oid
    if oid == "" {
      ownerId = userDocId
    }
    print("#BB \(ownerId)")
    registerAuthToken(authToken: authToken, refreshToken: refreshToken, oid: ownerId, bid: bid)
  }
  
  private func registerAuthToken(authToken: String, refreshToken: String, oid: String, bid: String) {
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.filterID = oid
    CoreInitConfigurations.shared.ownerID = bid
  }
}


extension DocAssistViewController {
  
  func registerUISdk() {
    registerFonts()
  }
  
  func registerFonts() {
    do {
      try Fonts.registerAllFonts()
    } catch {
      debugPrint("Failed to fetch fonts")
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
