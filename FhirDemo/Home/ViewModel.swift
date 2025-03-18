//
//  ViewModel.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/3/17.
//

import Foundation
import UIKit
import AuthenticationServices
import ModelsR4
import Combine

final class ViewModel {
    @Published private(set) var state = State.none
    
    private var session: ASWebAuthenticationSession?
    
    private let baseURI = "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0"
    
    private var audURI: String {
        baseURI + "/fhir"
    }
    
    private var codeURI: String {
        baseURI + "/auth/authorize"
    }
    
    private var tokenURI: String {
        baseURI + "/auth/token"
    }
    
    private var token: String?
}

extension ViewModel {
    func doAction(_ action: Action) {
        switch action {
        case let .login(window):
            doLogin(in: window)
        case .getPatients:
            doGetPatients()
        case .logout:
            doLogout()
        }
    }
}

private extension ViewModel {
    
    // MARK: - Do Shomething
    
    func doLogin(in window: UIWindow?) {
        guard let window else {
            state = .somethingWrong
            return
        }
        
        guard let url = makeCodeURL() else {
            state = .somethingWrong
            return
        }
        
        session = .init(url: url, callbackURLScheme: "app") { [weak self] callbackURL, error in
            self?.session = nil
            
            guard let self else {
                return
            }
            
            if error != nil {
                state = .somethingWrong
            }
            else if let callbackURL {
                handleCodeResponse(callbackURL: callbackURL)
            }
            else {
                state = .somethingWrong
            }
        }
        
        session?.presentationContextProvider = window
        session?.start()
    }
    
    func doLogout() {
        token = nil
        state = .logoutSuccess
    }
    
    func doGetToken(code: String) {
        guard let request = makeTokenRequest(code: code) else {
            state = .somethingWrong
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else {
                return
            }
            
            if error != nil {
                state = .somethingWrong
            }
            else {
                handleTokenResponse(data: data)
            }
        }.resume()
    }
    
    func doGetPatients() {
        guard let uri = URL(string: audURI + "/Patient"), let token else {
            state = .somethingWrong
            return
        }
        
        var request = URLRequest(url: uri)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else {
                return
            }
            
            if error != nil {
                state = .somethingWrong
            }
            else {
                handlePatientsResponse(data: data)
            }
        }.resume()
    }
    
    // MARK: - Handle Something
    
    func handleCodeResponse(callbackURL: URL) {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            state = .somethingWrong
            return
        }
        
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            state = .somethingWrong
            return
        }
        
        if code.isEmpty {
            state = .somethingWrong
            return
        }
        
        doGetToken(code: code)
    }
    
    func handleTokenResponse(data: Data?) {
        guard let data else {
            state = .somethingWrong
            return
        }
        
        guard let token = try? JSONDecoder().decode(Token.self, from: data) else {
            state = .somethingWrong
            return
        }
        
        if token.access_token.isEmpty {
            state = .somethingWrong
            return
        }
        
        self.token = token.access_token
        state = .loginSuccess
    }
    
    func handlePatientsResponse(data: Data?) {
        guard let data else {
            state = .somethingWrong
            return
        }
        
        do {
            let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: data)
            let patients = bundle.entry?.compactMap {
                $0.resource?.get(if: ModelsR4.Patient.self)
            } ?? []
            
            state = .getPatients(patients.compactMap { .init(patient: $0) })
        }
        catch {
            state = .somethingWrong
        }
    }
    
    // MARK: - Make Something
    
    func makeCodeURL() -> URL? {
        guard var urlComponents = URLComponents(string: codeURI) else {
            return nil
        }
        
        /*
        let codeVerifier = String(
            String(repeating: "a", count: 128).compactMap { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()
            }
        )*/
        
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
    
    func makeTokenRequest(code: String) -> URLRequest? {
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
}
