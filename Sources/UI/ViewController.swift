//
//  ViewController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 21/11/24.
//


//public class ViewController: UIViewController {
//  
//  var chatBotView: SomeMainView!
//  
//  public init(backgroundImage: UIImage? = nil) {
//    super.init(nibName: nil, bundle: nil)
//    
//    if let image = backgroundImage {
//      chatBotView = SomeMainView(backgroundImage: image)
//    } else {
//      
//      chatBotView = SomeMainView()
//    }
//  }
//  
//  required init?(coder: NSCoder) {
//         super.init(coder: coder)
//     }
//  
//  public override func viewDidLoad() {
//    super.viewDidLoad()
//    
//    self.navigationController?.setNavigationBarHidden(true, animated: false)
//    
//    
//    let uiHostingViewController = UIHostingController(rootView: chatBotView)
//    addChild(uiHostingViewController)
//    view.addSubview(uiHostingViewController.view)
//    
//    uiHostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      uiHostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
//      uiHostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//      uiHostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//      uiHostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//    ])
//  }
//}
import UIKit
import SwiftUI
import SwiftData

public class ViewController: UIViewController {
  
  var chatBotView: SomeMainView!
<<<<<<< HEAD
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = nil, editButtonColor: Color? = nil, backButtonColor: Color? = nil) {
    super.init(nibName: nil, bundle: nil)
    
    chatBotView = SomeMainView(backgroundImage: backgroundImage,emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, backButtonColor: backButtonColor)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
=======
>>>>>>> 0c4f791 (Fixed Bugs and working code)
  
  // Custom initializer to accept the optional UIImage for background
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = nil,
    editButtonColor: Color? = nil,
    backButtonColor: Color? = nil,
    ctx: ModelContext
  ) {
    super.init(nibName: nil, bundle: nil)
    
<<<<<<< HEAD
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    
    let uiHostingViewController = UIHostingController(rootView: chatBotView)
    
    addChild(uiHostingViewController)
    view.addSubview(uiHostingViewController.view)
=======
>>>>>>> 0c4f791 (Fixed Bugs and working code)
    
    // Pass the background image to SomeMainView
    chatBotView = SomeMainView(
      backgroundImage: backgroundImage,
      emptyMessageColor: emptyMessageColor,
      editButtonColor: editButtonColor,
      backButtonColor: backButtonColor,
      ctx: ctx
    )
  }
<<<<<<< HEAD
=======

    // Required initializer for ViewController without storyboard
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the UIHostingController
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Create a UIHostingController with the configured SomeMainView
        let uiHostingViewController = UIHostingController(rootView: chatBotView)
        
        // Add the UIHostingController to the view controller hierarchy
        addChild(uiHostingViewController)
        view.addSubview(uiHostingViewController.view)
        
        // Set up constraints for the UIHostingController's view
        uiHostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            uiHostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            uiHostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            uiHostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uiHostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
>>>>>>> 0c4f791 (Fixed Bugs and working code)
}
