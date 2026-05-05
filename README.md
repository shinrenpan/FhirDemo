# FhirDemo

SMART on FHIR OAuth 2.0 示範 App，展示如何透過 Authorization Code Flow 授權並查詢 FHIR R4 病患資料。

部落格文章：https://joepan.hashnode.dev/fhir-oauth-demo

## 功能

- SMART on FHIR OAuth 2.0 授權（Authorization Code Flow）
- 透過 `ASWebAuthenticationSession` 完成瀏覽器授權
- 取得 access token 後查詢 FHIR R4 Patient 資源
- 解析 FHIR Bundle 並顯示病患姓名與生日

## 架構

採用 MVVMC 架構，AppDelegate / SceneDelegate 管理 UIKit window，HostController 橋接 SwiftUI 畫面：

| 層 | 檔案 | 職責 |
|---|---|---|
| M | `HomeViewModel+Models.swift` | State / Patient / TokenDTO |
| V | `HomeView.swift` | SwiftUI 畫面 |
| VM | `HomeViewModel.swift` | 業務邏輯、OAuth 流程、API 呼叫 |
| C | `HomeHostController.swift` | UIKit 橋接、Router 導航 |

## 技術

- Swift 6 / iOS 18
- UIKit（AppDelegate + SceneDelegate）+ SwiftUI（`UIHostingController`）
- Swift Observation（`@Observable`）
- Swift Concurrency（`async/await`）
- [Apple FHIRModels](https://github.com/apple/FHIRModels) `0.6.1`（FHIR R4）
- SMART Health IT Sandbox
