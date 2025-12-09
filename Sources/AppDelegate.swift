//
//  AppDelegate.swift
//
//  Created by Joe Pan on 2025/3/17.
//

import UIKit
import AuthenticationServices

@main
class AppDelegate: UIResponder {
  var window: UIWindow?
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let bounds = UIScreen.main.bounds
    let window = UIWindow(frame: bounds)
    window.backgroundColor = .white
    let vc = HomeViewController(viewModel: .init())
    window.rootViewController = UINavigationController(rootViewController: vc)
    self.window = window
    window.makeKeyAndVisible()

    return true
  }
}
