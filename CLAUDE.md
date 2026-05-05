# FhirDemo

## App 架構
使用 UIKit（AppDelegate / SceneDelegate 管理 window), 而非 SwiftUI

## Skill Directory Map

> 所有路徑基於 `~/.claude/skills/`
> 載入目錄即載入其下所有檔案（SKILL.md + references/）

### 不需載入
- `skip-crossplatform`

## Architecture: MVVMC

本專案採用 MVVMC 架構，四層職責嚴格分離：

| 層 | 類別命名 | 職責 |
|---|---|---|
| M | `FeatureViewModel+Models.swift` | State / Domain Models / DTOs |
| V | `FeatureView` | SwiftUI 三層架構 L1/L2/L3 |
| VM | `FeatureViewModel` | @Observable @MainActor，doAction 單一進入點 |
| C | `FeatureHostController` | UIKit 橋接，Router 導航唯一責任者 |

## Project Structure

```
Sources/
├── AppDelegate.swift                # App 生命週期
├── SceneDelegate.swift              # Window 建立
└── Home/
    ├── HomeView.swift               # V: SwiftUI
    ├── HomeViewModel.swift          # VM: @Observable @MainActor
    ├── HomeViewModel+Models.swift   # M: State / Domain Models / DTOs
    └── HomeHostController.swift     # C: UIHostingController
```

## ViewModel 結構

本專案**不使用 `ViewModel` protocol**，pattern 直接定義在 class 上：

```swift
@Observable
@MainActor
final class FeatureViewModel {
  enum Action: Sendable { ... }

  var state: State = .init()

  @ObservationIgnored
  var onAction: (@MainActor (Action) -> Void)?

  func doAction(_ action: Action) async { ... }
}
```