//
//  AppDelegate.swift
//
//  Created by Joe Pan on 2025/3/17.
//

import UIKit
import AuthenticationServices

@UIApplicationMain class AppDelegate: UIResponder {
    var window: UIWindow?
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let bounds = UIScreen.main.bounds
        let window = UIWindow(frame: bounds)
        window.backgroundColor = .white
        window.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window = window
        window.makeKeyAndVisible()

        
        return true
    }
}

extension UIWindow: @retroactive ASWebAuthenticationPresentationContextProviding {

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {

        // UIWindow 本來就有遵守 ASPresentationAnchor，所以可以直接回傳 self。
        return self
    }
}

func authorize(in window: UIWindow, completionHandler: @escaping (String) -> Void) {

    // 產生一個長度 128 的隨機字串
    let codeVerifier = String(
        String(repeating: "a", count: 128).compactMap { _ in
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()
        }
    )

    // 在 app 後台中的資訊
    let clientID = "joefhir"
    let redirectURI = "app://done"

    // 1. 使用 ASWebAuthenticationSession 獲取 authorization code
    retrieveCode(in: window, clientID: clientID, redirectURI: redirectURI, codeVerifier: codeVerifier) { code in

        // 2. 使用 URLSession 拿 authorization code 去交換 access token
        //retrieveToken(code: code, clientID: clientID, redirectURI: redirectURI, codeVerifier: codeVerifier) { token in

            // 3. 回傳 access token
        //    completionHandler(token)
        //}
    }
}

var session: ASWebAuthenticationSession?

func retrieveCode(

    // 用來顯示的視窗
    in window: UIWindow,

    // 會跟第二步的 retrieveToken 函數共用的變數就做成參數
    // 告訴授權伺服器這是哪個 app
    clientID: String,

    // 在 App 後台裡新增的 redirect URI
    redirectURI: String,

    // 這是用來在行動裝置 app 上補強 Authorization Code flow 的叫做 PKCE 的機制，用一個臨時產生的隨機字串（code verifier）來當 client secret，在請求 authorization code 跟請求 token 時各傳送一次給授權伺服器檢查，以避免 authorization code 在用瀏覽器傳輸時遭到中間人攔截。
    codeVerifier: String,

    completionHandler: @escaping (String) -> Void
) {
    
    // 用 URLComponents 來操作 query 字串
    // 實際參數都需要參考 Dropbox（或其他服務商）的開發者文件
    var urlComponents = URLComponents(string: "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCJ0b2tlbl9pbnZhbGlkX3Rva2VuIiwiIiwiIiwxLDEsIiJd/auth/authorize")!
    
    urlComponents.queryItems = [
        
//        // 告訴授權伺服器我們要走 authorization code 流程
        URLQueryItem(name: "response_type", value: "code"),
//        
//        //URLQueryItem(name: "client_id", value: "joefhir"),
        URLQueryItem(name: "redirect_uri", value: "app://done"),
//        
//        // 詳細的參數請參見 Dropbox 開發者文件
//        URLQueryItem(name: "code_challenge", value: codeVerifier),
//        //URLQueryItem(name: "code_challenge_method", value: "json"),
        URLQueryItem(name: "aud", value: "https://launch.smarthealthit.org/v/r4/sim/WzIsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCJ0b2tlbl9pbnZhbGlkX3Rva2VuIiwiIiwiIiwxLDEsIiJd/fhir"),
//        URLQueryItem(name: "code_challenge_method", value: "S256"),
        URLQueryItem(name: "scope", value: "user/*.*")
    ]
    
    // 取出建構好的 URL
    let url = urlComponents.url!
    
    // 提供獲取 authorization code 用的 URL 與回傳 URL 的 scheme。
    // 當使用者成功授權後，授權伺服器會傳送回傳 URL 給 session，而 session 會直接關掉瀏覽器並呼叫 completionHandler。
    session = ASWebAuthenticationSession(url: url, callbackURLScheme: "app", completionHandler:  { callbackURL, error in

        // 使用者成功授權後，從回傳 URL 中抽取 authorization code 以進行後續步驟。
        print(callbackURL ?? "No code")
        session = nil
        completionHandler("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb250ZXh0Ijp7Im5lZWRfcGF0aWVudF9iYW5uZXIiOnRydWUsInNtYXJ0X3N0eWxlX3VybCI6Imh0dHBzOi8vbGF1bmNoLnNtYXJ0aGVhbHRoaXQub3JnL3NtYXJ0LXN0eWxlLmpzb24ifSwicmVkaXJlY3RfdXJpIjoiYXBwOi8vZG9uZSIsInBrY2UiOiJhdXRvIiwiY2xpZW50X3R5cGUiOiJwdWJsaWMiLCJjb2RlX2NoYWxsZW5nZV9tZXRob2QiOiJTMjU2IiwiY29kZV9jaGFsbGVuZ2UiOiJSMG0xeTAwdXZrQms0cXNOWTlrc0tKdkF0Z2h3aTF6WWJoZVRqSTNQOXRRUGxyczhLcHE5cmtrSHV4SzFuYUd5OUZaandTdm9LSVVuc01MZ2FJTm5PcUhSM1VTZFh4Vmd6OG1uTU9JM0VJc0xxSlZNSFVhaDdITFlVZjRyRWVhNCIsImlhdCI6MTc0MjIwOTk0MywiZXhwIjoxNzQyMjEwMjQzfQ.FVIzJ1_8sjv1y1uP3EFHbYqFhPwDs16r-QXRZVLHgMQ")
    })

    // 提供 session 用來顯示的視窗。
    session?.presentationContextProvider = window

    // 告訴 session 啟動流程。
    session?.start()
    
}

/*
func retrieveToken(
    code: String,
    clientID: String,
    redirectURI: String,
    codeVerifier: String,
    completionHandler: @escaping (String) -> Void
) {
    
    // 建構 POST 請求
    let url = URL(string: "https://launch.smarthealthit.org/v/r4/auth/authorize")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // 這邊用 URLComponents 來產生 query 字串並轉成 Data
    var urlComponents = URLComponents()
    urlComponents.queryItems = [
        URLQueryItem(name: "grant_type", value: "authorization_code"),
        URLQueryItem(name: "code", value: code),
        URLQueryItem(name: "client_id", value: clientID),
        URLQueryItem(name: "redirect_uri", value: redirectURI),
        URLQueryItem(name: "code_verifier", value: codeVerifier),
        URLQueryItem(name: "code_challenge_method", value: "S256")
    ]
    request.httpBody = urlComponents.query?.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        
        guard let data = data else { return }
        
        // 用一個臨時的 Codable struct 來解 response
        struct TokenResponse: Codable {
            var access_token: String
        }
        //let tokenResponse = try! JSONDecoder().decode(TokenResponse.self, from: data)
        
        // 回傳從 response 中解出的 access token
        //completionHandler(tokenResponse.access_token)
        //completionHandler(code)
    }
    task.resume()
}*/

/*
final class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        authorize(in: view.window!) { token in
            
            // 儲存與使用 token
            print(token)
            
            let url = URL(string: "https://launch.smarthealthit.org/v/r4/sim/WzMsIjM5ZTUzYzZmLTMwOWItNGVkNy1iNjUwLTc5YTRlZjdiMWU5OSIsIiIsIk1BTlVBTCIsMSwxLDAsIiIsIiIsIiIsIiIsIiIsIiIsIiIsMCwxLCIiXQ/fhir/Location")!
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Error:", error)
                    return
                }
                
                guard let data = data else {
                    print("No data.")
                    return
                }
                
                let string = String(data: data, encoding: .utf8)!
                print(string)
            }.resume()
        }
    }
}
*/
