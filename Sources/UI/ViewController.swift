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
      deviceType: String? = "phone"
  ) {
      super.init(nibName: nil, bundle: nil)
      switch deviceType?.lowercased() {
      case "ipad":
          let ipadView = IpadChatView(
              backgroundColor: backgroundColor,
              emptyMessageColor: emptyMessageColor,
              editButtonColor: editButtonColor,
              subTitle: subTitle,
              ctx: ctx
          )
          uiHostingController = UIHostingController(rootView: AnyView(ipadView))
      
      default:
          let iphoneView = SomeMainView(
              backgroundColor: backgroundColor,
              emptyMessageColor: emptyMessageColor,
              editButtonColor: editButtonColor,
              subTitle: subTitle,
              ctx: ctx
          )
          uiHostingController = UIHostingController(rootView: AnyView(iphoneView))
      }
  }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
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
}

public class ViewControllerForIpadPatient: UIViewController {
  
  var docAssistView: AnyView
  var vm: ChatViewModel
  public init(
    backgroundColor: Color? = nil,
    ctx: ModelContext,
    patientSubtitle: String?,
    oid: String
  ) {
    vm = ChatViewModel(context: ctx)
    let session = vm.createSession(subTitle: patientSubtitle, oid: oid)
    let newSessionView = NewSessionView(session: session, viewModel: vm, backgroundColor: backgroundColor, patientName: patientSubtitle ?? "", calledFromPatientContext: true)
    docAssistView = AnyView(newSessionView.modelContext(ctx))
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
}
