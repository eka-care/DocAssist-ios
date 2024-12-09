//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI
import SwiftData

public class ViewController: UIViewController {
  
  var chatBotView: SomeMainView!
  
  // Custom initializer to accept the optional UIImage for background
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    subTitle: String? = nil,
    ctx: ModelContext
  ) {
    super.init(nibName: nil, bundle: nil)
    
      chatBotView = SomeMainView(
      backgroundImage: backgroundImage,
      emptyMessageColor: emptyMessageColor,
      editButtonColor: editButtonColor,
      subTitle: subTitle,
      ctx: ctx
    )
  }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let uiHostingViewController = UIHostingController(rootView: chatBotView)
        
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

public class ViewControllerForIpad: UIViewController {
  
  var chatBotView: IpadChatView!
  
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    subTitle: String? = nil,
    ctx: ModelContext
  ) {
    super.init(nibName: nil, bundle: nil)
    
    chatBotView = IpadChatView(
      backgroundImage: backgroundImage,
      emptyMessageColor: emptyMessageColor,
      editButtonColor: editButtonColor,
      subTitle: subTitle,
      ctx: ctx
    )

  }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let uiHostingViewController = UIHostingController(rootView: chatBotView)
        
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
