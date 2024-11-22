//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI

public class ViewController: UIViewController {
  
  var chatBotView: SomeMainView!
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = nil, editButtonColor: Color? = nil) {
    super.init(nibName: nil, bundle: nil)
    
    chatBotView = SomeMainView(backgroundImage: backgroundImage,emptymessageColor: emptyMessageColor, editButtonColor: editButtonColor)
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
