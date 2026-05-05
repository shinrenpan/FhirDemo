//
//  HomeHostController.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import SwiftUI
import AuthenticationServices

@MainActor
final class HomeHostController: UIHostingController<HomeView> {

  // MARK: - ViewModel

  let viewModel: HomeViewModel

  // MARK: - OAuth Session

  private var oAuthSession: ASWebAuthenticationSession?

  // MARK: - Init

  init(viewModel: HomeViewModel) {
    self.viewModel = viewModel
    let view = HomeView(viewModel: viewModel)
    super.init(rootView: view)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Lifecycle

extension HomeHostController {
  override func viewDidLoad() {
    super.viewDidLoad()
    listenSelfAction()
  }
}

// MARK: - Router

private extension HomeHostController {
  func listenSelfAction() {
    viewModel.onAction = { [weak self] action in
      switch action {
      case .view, .oauth, .apiRequest, .apiResponse:
        break

      case let .router(router):
        self?.handleSelfRouter(router)
      }
    }
  }

  func handleSelfRouter(_ router: HomeViewModel.Router) {
    switch router {
    case let .showOAuthView(url):
      showOAuthView(url)
    }
  }

  func showOAuthView(_ url: URL) {
    oAuthSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "app") { [weak self] callbackURL, error in
      if error != nil {
        Task { await self?.viewModel.doAction(.oauth(.failure)) }
        return
      }
      Task { await self?.viewModel.doAction(.oauth(.success(callbackURL))) }
    }
    oAuthSession?.presentationContextProvider = self
    oAuthSession?.prefersEphemeralWebBrowserSession = true
    oAuthSession?.start()
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension HomeHostController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    view.window!
  }
}
