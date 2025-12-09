//
//  HomeViewController.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import SwiftUI
import AuthenticationServices

final class HomeViewController: UIHostingController<HomeView> {
  private let viewModel: HomeViewModel

  init(viewModel: HomeViewModel) {
    self.viewModel = viewModel
    let view = HomeView(viewModel: viewModel)
    super.init(rootView: view)
  }

  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    listenAction()
  }
}

// MARK: - Listen

private extension HomeViewController {
  func listenAction() {
    viewModel.onAction = { [weak self] action in
      switch action {
      case .view, .oauth, .apiRequest, .apiResponse:
        break

      case let .router(router):
        self?.handleRouter(router)
      }
    }
  }

  func handleRouter(_ router: HomeViewModel.Router) {
    switch router {
    case let .showOAuthView(url):
      showOAuthView(url)
    }
  }

  func showOAuthView(_ url: URL) {
    var session: ASWebAuthenticationSession?

    session = ASWebAuthenticationSession(url: url, callbackURLScheme: "app") { [weak self] callbackURL, error in
      if error != nil {
        Task { await self?.viewModel.doAction(.oauth(.failure)) }
        return
      }

      Task { await self?.viewModel.doAction(.oauth(.success(callbackURL))) }
    }

    if let session {
      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = true
      session.start()
    }
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension HomeViewController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    view.window!
  }
}
