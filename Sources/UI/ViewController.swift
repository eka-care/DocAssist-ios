//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//

import UIKit
import SwiftUI

public class ViewController: UIViewController {
  
  var ChatBotView = SomeMainView()
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    let uiHostingViewController = UIHostingController(rootView: ChatBotView)
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
