//
//  FloatingButtonController.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 27/02/25.
//
import UIKit
import SwiftUI
import EkaVoiceToRx

class FloatingButtonController: UIViewController {
    private(set) var button: UIView!
    private let window: FloatingButtonWindow = FloatingButtonWindow()
    static let shared: FloatingButtonController = FloatingButtonController()
    private var initialButtonCenter: CGPoint?

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private init() {
        super.init(nibName: nil, bundle: nil)
    }

    public func showFloatingButton(viewModel: VoiceToRxViewModel) {
        window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
        window.isHidden = false
        window.rootViewController = self
        loadView(viewModel: viewModel)
    }

    public func hideFloatingButton() {
        window.windowLevel = UIWindow.Level(rawValue: 0)
        window.isHidden = true
        window.rootViewController = self
    }

    private func loadView(viewModel: VoiceToRxViewModel) {
        let view = UIView()
        guard let button = UIHostingController(rootView: PictureInPictureView(voiceToRxViewModel: viewModel)).view else { return }
        button.frame = CGRect(x: (UIApplication.shared.keyWindow?.frame.width ?? 0), y: (UIApplication.shared.keyWindow?.frame.height)!/4, width: 200, height: 50)
        view.addSubview(button)
        self.view = view
        self.button = button
        window.button = button
        
        animateToNearestCorner(button)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        button.addGestureRecognizer(panGesture)
    }

    @objc public func onClickStickyButton() {
        let mainStoryboard = UIStoryboard(name: "TimerTab", bundle: Bundle.main)
        let notificationSetterViewController = mainStoryboard.instantiateViewController(withIdentifier: "NotificationSetterViewController")
        guard let mainViewController = UIApplication.shared.keyWindow!.rootViewController as? UITabBarController else {
            return
        }
        if let presentedViewController = mainViewController.presentedViewController {
            guard let navigationController = presentedViewController.navigationController else {
                presentedViewController.present(notificationSetterViewController, animated: true, completion: nil)
                return
            }
            navigationController.pushViewController(notificationSetterViewController, animated: true)
        } else {
            guard let navigationController = mainViewController.navigationController else {
                mainViewController.present(notificationSetterViewController, animated: true, completion: nil)
                return
            }
            navigationController.pushViewController(notificationSetterViewController, animated: true)
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let buttonView = gesture.view!
        
        switch gesture.state {
        case .began:
            initialButtonCenter = buttonView.center
            
        case .changed:
            let translation = gesture.translation(in: view)
            buttonView.center = CGPoint(
                x: buttonView.center.x + translation.x,
                y: buttonView.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: view)
            
            let screenBounds = UIScreen.main.bounds
            let halfButtonWidth = buttonView.bounds.width / 2
            let halfButtonHeight = buttonView.bounds.height / 2
            
            if buttonView.center.x < halfButtonWidth {
                buttonView.center.x = halfButtonWidth
            } else if buttonView.center.x > screenBounds.width - halfButtonWidth {
                buttonView.center.x = screenBounds.width - halfButtonWidth
            }
            
            if buttonView.center.y < halfButtonHeight {
                buttonView.center.y = halfButtonHeight
            } else if buttonView.center.y > screenBounds.height - halfButtonHeight {
                buttonView.center.y = screenBounds.height - halfButtonHeight
            }
            
        case .ended, .cancelled:
            animateToNearestCorner(buttonView)
            
        default:
            break
        }
    }
    
    private func animateToNearestCorner(_ buttonView: UIView) {
        let screenBounds = UIScreen.main.bounds
        let buttonWidth = buttonView.bounds.width
        let buttonHeight = buttonView.bounds.height
        let margin: CGFloat = 10.0
        
        let currentX = buttonView.center.x
        let currentY = buttonView.center.y
        
        let distanceToLeftEdge = currentX
        let distanceToRightEdge = screenBounds.width - currentX
        let distanceToTopEdge = currentY
        let distanceToBottomEdge = screenBounds.height - currentY
        
        let minDistance = min(distanceToLeftEdge, distanceToRightEdge, distanceToTopEdge, distanceToBottomEdge)
        
        var targetPoint = buttonView.center
        
        if minDistance == distanceToLeftEdge {
            targetPoint.x = buttonWidth / 2 + margin
        } else if minDistance == distanceToRightEdge {
            targetPoint.x = screenBounds.width - buttonWidth / 2 - margin
        } else if minDistance == distanceToTopEdge {
            targetPoint.y = buttonHeight / 2 + margin
        } else {
            targetPoint.y = screenBounds.height - buttonHeight / 2 - margin
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            buttonView.center = targetPoint
        }, completion: nil)
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let xDistance = point1.x - point2.x
        let yDistance = point1.y - point2.y
        return sqrt(xDistance * xDistance + yDistance * yDistance)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

private class FloatingButtonWindow: UIWindow {
    var button: UIView?

    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let button = button else { return false }
        let buttonPoint = convert(point, to: button)
        return button.point(inside: buttonPoint, with: event)
    }
}
