//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI
import SwiftData

public class DocAssistViewController: UIViewController {
  private var docAssistView: UIView!
  private var uiHostingController: UIHostingController<AnyView>!
  
  public init(
    backgroundColor: Color? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    subTitle: String? = nil,
    ctx: ModelContext,
    deviceType: String? = "phone",
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText
  ) {
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
        delegate: delegate
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
        delegate: delegate
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
      uiHostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 0),
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
}

public class ViewControllerForIpadPatient: UIViewController {
  
  var docAssistView: AnyView
  var vm: ChatViewModel
  public init(
    backgroundColor: Color? = nil,
    ctx: ModelContext,
    patientSubtitle: String?,
    oid: String,
    userDocId: String,
    userBId: String,
    delegate: ConvertVoiceToText
  ) {
    vm = ChatViewModel(context: ctx, delegate: delegate)
    let session = vm.createSession(subTitle: patientSubtitle, oid: oid, userDocId: userDocId, userBId: userBId)
    let activeChatView = ActiveChatView(session: session, viewModel: vm, backgroundColor: backgroundColor, patientName: patientSubtitle ?? "", calledFromPatientContext: true)
    docAssistView = AnyView(activeChatView.modelContext(ctx))
    super.init(nibName: nil, bundle: nil)
    
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
