//
//  HomeViewModel.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
  enum Action: Equatable {
    case view(ViewAction)
    case router(Router)
    case oauth(OAuth)
    case apiRequest(APIRequest)
    case apiResponse(APIResponse)
  }

  var onAction: (@MainActor (Action) -> Void)?

  var state: State = .init()

  func doAction(_ action: Action) async {
    switch action {
    case let .view(action):
      await handleViewAction(action)

    case let .router(router):
      await handleRouter(router)

    case let .oauth(oauth):
      await handleOAuth(oauth)

    case let .apiRequest(request):
      await handleAPIRequest(request)

    case let .apiResponse(response):
      await handleAPIResponse(response)
    }
  }
}

// MARK: - View Action

extension HomeViewModel {
  enum ViewAction: Equatable {
    case loginButtonDidTap
    case logoutButtonDidTap
  }

  private func handleViewAction(_ action: ViewAction) async {
    switch action {
    case .loginButtonDidTap:
      if state.viewStatus == .loggedIn {
        return
      }
      if let url = makeOAuthURL() {
        state.viewStatus = .loading
        await doAction(.router(.showOAuthView(url)))
      }
      else {
        state.viewStatus = .failed
      }

    case .logoutButtonDidTap:
      state.viewStatus = .logout
    }
  }
}

// MARK: - Router

extension HomeViewModel {
  enum Router: Equatable {
    case showOAuthView(URL)
  }

  private func handleRouter(_ router: Router) async {
    onAction?(.router(router))
  }
}

// MARK: - OAuth

extension HomeViewModel {
  enum OAuth: Equatable {
    case success(_ url: URL?)
    case failure
    case handleCallback(_ url: URL)
  }

  private func handleOAuth(_ oauth: OAuth) async {
    switch oauth {
    case let .success(url):
      if let url {
        await doAction(.oauth(.handleCallback(url)))
      }
      else {
        state.viewStatus = .failed
      }
      
    case .failure:
      state.viewStatus = .failed

    case let .handleCallback(url):
      if let code = makeOAuthCode(url) {
        await doAction(.apiRequest(.getToken(code)))
      }
      else {
        state.viewStatus = .failed
      }
    }
  }
}

// MARK: - API Request

extension HomeViewModel {
  enum APIRequest: Equatable {
    case getToken(_ code: String)
    case getPatients(_ token: String)
  }

  private func handleAPIRequest(_ request: APIRequest) async {
    switch request {
    case let .getToken(code):
      if let request = makeTokenURLRequest(code: code) {
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
          if error != nil {
            Task { @MainActor in self?.state.viewStatus = .failed }
          }
          else {
            Task { await self?.doAction(.apiResponse(.getToken(data))) }
          }
        }.resume()
      }
      else {
        state.viewStatus = .failed
      }

    case let .getPatients(token):
      if let request = makePatientURLRequest(token: token) {
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
          if error != nil {
            Task { @MainActor in self?.state.viewStatus = .failed }
          }
          else {
            Task { await self?.doAction(.apiResponse(.getPatients(data))) }
          }
        }.resume()
      }
      else {
        state.viewStatus = .failed
      }
    }
  }
}

// MARK: - API Response

extension HomeViewModel {
  enum APIResponse: Equatable {
    case getToken(_ data: Data?)
    case getPatients(_ data: Data?)
  }

  private func handleAPIResponse(_ response: APIResponse) async {
    switch response {
    case let .getToken(data):
      if let data, let token = makeToken(data) {
        await doAction(.apiRequest(.getPatients(token)))
      }
      else {
        state.viewStatus = .failed
      }

    case let .getPatients(data):
      if let data {
        do {
          state.patients = try DisplayPatient.with(data)
          state.viewStatus = .loggedIn
        }
        catch {
          state.viewStatus = .failed
        }
      }
      else {
        state.viewStatus = .failed
      }
    }
  }
}

// MARK: - Make

private extension HomeViewModel {
  func makeOAuthURL() -> URL? {
    let authURI = "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0/auth/authorize"
    let audURI = "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0/fhir"

    guard var urlComponents = URLComponents(string: authURI) else {
      return nil
    }

    urlComponents.queryItems = [
      .init(name: "response_type", value: "code"),
      .init(name: "redirect_uri", value: "app://"),
      .init(name: "aud", value: audURI),
      .init(name: "scope", value: "patient/*.cruds"),
      //    .init(name: "code_challenge_method", value: "S256"),
      //    .init(name: "code_challenge", value: codeVerifier),
    ]

    guard let url = urlComponents.url else {
      return nil
    }

    return url
  }

  func makeOAuthCode(_ url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }

    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
      return nil
    }

    return code.isEmpty ? nil : code
  }

  func makeTokenURLRequest(code: String) -> URLRequest? {
    let tokenURI = "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0/auth/token"

    guard let components = URLComponents(string: tokenURI) else {
        return nil
    }

    guard let url = components.url else {
        return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    //request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    var urlComponents = URLComponents()
    urlComponents.queryItems = [
        URLQueryItem(name: "grant_type", value: "authorization_code"),
        URLQueryItem(name: "code", value: code),
        //URLQueryItem(name: "client_id", value: clientID),
        URLQueryItem(name: "redirect_uri", value: "app://"),
        //URLQueryItem(name: "code_verifier", value: codeVerifier),
        //URLQueryItem(name: "code_challenge_method", value: "S256")
    ]
    request.httpBody = urlComponents.query?.data(using: .utf8)

    return request
  }

  func makeToken(_ data: Data?) -> String? {
    guard let data else {
      return nil
    }

    guard let result = try? JSONDecoder().decode(Token.self, from: data) else {
      return nil
    }

    return result.access_token.isEmpty ? nil : result.access_token
  }

  func makePatientURLRequest(token: String) -> URLRequest? {
    let patientURI = "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0/fhir/Patient"

    guard let urlComponents = URLComponents(string: patientURI) else {
      return nil
    }

    guard let url = urlComponents.url else {
      return nil
    }

    var result = URLRequest(url: url)
    result.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    return result
  }
}
