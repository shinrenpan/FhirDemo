//
//  SceneDelegate.swift
//
//  Created by Joe Pan on 2025/3/17.
//

import UIKit

class SceneDelegate: UIResponder {
  var window: UIWindow?
}

// MARK: - UIWindowSceneDelegate

extension SceneDelegate: UIWindowSceneDelegate {
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    window.backgroundColor = .white
    let vc = HomeHostController(viewModel: .init())
    window.rootViewController = UINavigationController(rootViewController: vc)
    self.window = window
    window.makeKeyAndVisible()
  }
}
