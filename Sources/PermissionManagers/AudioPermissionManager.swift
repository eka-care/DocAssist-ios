//
//  AudioPermissionManager.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 17/08/25.
//
import AVFoundation
import UIKit

final class AudioPermissionManager {
  
  static let shared = AudioPermissionManager()
  private init() {}
  
  var alertTitle: String = "Microphone Access Denied"
  var alertMessage: String = "To record audio, please enable microphone access in Settings."
  
  func checkAndRequestMicrophonePermission(onGranted: @escaping () -> Void) {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    
    switch status {
    case .authorized:
      onGranted()
      
    case .denied:
      setDeniedAlert()
      
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            onGranted()
          } else {
            self?.setDeniedAlert()
          }
        }
      }
      
    case .restricted:
      alertTitle = "Microphone Access Restricted"
      alertMessage = "Microphone access is restricted and cannot be changed."
      showPermissionAlert()
      
    @unknown default:
      alertTitle = "Error"
      alertMessage = "Unknown microphone permission status."
      showPermissionAlert()
    }
  }
  
  private func setDeniedAlert() {
    alertTitle = "Microphone Access Denied"
    alertMessage = "To record audio, please enable microphone access in Settings."
    showPermissionAlert()
  }
  
  private func showPermissionAlert() {
    DispatchQueue.main.async {
      guard let topVC = Self.topViewController() else { return }
      
      let alert = UIAlertController(
        title: self.alertTitle,
        message: self.alertMessage,
        preferredStyle: .alert
      )
      
      alert.addAction(UIAlertAction(title: "OK", style: .cancel))
      
      if AVCaptureDevice.authorizationStatus(for: .audio) == .denied {
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
          self.openAppSettings()
        })
      }
      
      topVC.present(alert, animated: true)
    }
  }
  
  private static func topViewController(base: UIViewController? = {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      return windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }
    return nil
  }()) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      return topViewController(base: tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }
  
  func openAppSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
    if UIApplication.shared.canOpenURL(settingsURL) {
      UIApplication.shared.open(settingsURL)
    }
  }
}
