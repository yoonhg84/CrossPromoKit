# CrossPromoKit PRD

> 마지막 업데이트: 2026-08-12

## 개요

CrossPromoKit은 iOS 앱 간 크로스 프로모션을 위한 Swift Package입니다. 개발자가 자신의 앱 포트폴리오 내에서 다른 앱을 홍보할 수 있도록 설계되었으며, 원격 JSON 구성, 캐싱, SKOverlay 통합을 지원합니다.

## 핵심 가치

- 간편한 통합: 몇 줄의 코드로 크로스 프로모션 기능 추가
- 유연한 구성: 원격 JSON을 통한 동적 앱 목록 관리
- 다국어 지원: 카탈로그 태그라인과 패키지 내장 UI 문자열 모두 영어·한국어·일본어 제공
- 오프라인 우선: 네트워크 실패 시 캐시로 조용히 폴백하며 에러 다이얼로그를 띄우지 않음
- 접근성: VoiceOver에서 앱 한 개가 한 요소로 읽히도록 라벨/힌트 제공
- 네이티브 경험: SKOverlay를 통한 인앱 App Store 표시
- 의존성 없음: 시스템 프레임워크만 사용

## 타겟 사용자

- 여러 앱을 보유한 iOS 개발자
- 앱 포트폴리오 내 사용자 유입을 원하는 인디 개발자
- 간단한 크로스 프로모션 솔루션을 찾는 팀

## 기능 목록

### 핵심 기능 (Core)

| 기능 | 설명 | 상태 |
|------|------|------|
| MoreAppsView | 프로모션 앱 목록을 표시하는 SwiftUI 뷰. `PromoConfig` 필수, `forceRefresh` 바인딩으로 외부에서 새로고침 트리거 | ✅ 완료 |
| PromoService | 데이터 로딩, 캐싱, 필터링, 이벤트 방출 관리 (`@MainActor` + `@Observable`) | ✅ 완료 |
| PromoConfig | 카탈로그 JSON URL 및 현재 앱 ID 구성 | ✅ 완료 |
| AppCatalog | 카탈로그 루트 모델 (`apps`, 선택적 `promoRules`) | ✅ 완료 |
| PromoApp | 프로모션 앱 데이터 모델 | ✅ 완료 |
| LocalizedText | 다국어 태그라인 (en 필수, ko·ja 선택) | ✅ 완료 |
| NetworkClient | 원격 JSON 데이터 가져오기 (`https://` 및 `file://` 지원) | ✅ 완료 |
| CacheManager | UserDefaults 기반 24시간 캐싱 | ✅ 완료 |
| 카탈로그 URL별 캐시 스코핑 | 캐시 키를 카탈로그 URL의 SHA256 다이제스트로 분리해 여러 `PromoConfig`가 서로 덮어쓰지 않음. 구버전 전역 키는 자동 정리 | ✅ 완료 |
| 만료 캐시 오프라인 폴백 | 네트워크 실패 시 만료된 캐시도 그대로 노출 (빈 목록보다 오래된 프로모션이 유용) | ✅ 완료 |
| promoRules 필터링 | 호스트 앱 제외 + 카탈로그가 정의한 화이트리스트 적용, JSON 순서 유지 | ✅ 완료 |
| AppStoreOverlayPresenter | SKOverlay 표시/해제를 프로토콜로 추상화 (테스트 대체 가능, 이전 오버레이 자동 해제) | ✅ 완료 |
| 오버레이 폴백 알림 | 전경 window scene이 없어 오버레이를 못 띄우면 App Store 직접 열기 알림 표시 | ✅ 완료 |
| PromoEventDelegate | 노출(impression) 및 탭(tap) 이벤트 위임, 세션당 노출 1회 | ✅ 완료 |
| 3단계 폴백 | Network → Cache → Empty State | ✅ 완료 |

### UI 컴포넌트

| 기능 | 설명 | 상태 |
|------|------|------|
| PromoAppRow | 개별 앱 행 컴포넌트 (아이콘/이름/카테고리/태그라인) | ✅ 완료 |
| AsyncAppIcon | 비동기 아이콘 로딩 (`sf-symbol://` 스킴 지원) | ✅ 완료 |
| EmptyStateView | 빈 상태 / 오프라인 상태 표시 뷰 | ✅ 완료 |
| WarmEmbraceTokens | 색상·간격·타이포그래피 디자인 토큰 시스템 | ✅ 완료 |
| 접근성 | PromoAppRow를 단일 VoiceOver 요소로 병합하고 라벨·힌트 제공, 장식 요소는 숨김 | ✅ 완료 |

### 다국어 (Localization)

| 항목 | 설명 | 상태 |
|------|------|------|
| 카탈로그 태그라인 | `LocalizedText`가 기기 언어에 맞춰 en/ko/ja 중 선택, 누락 시 영어로 폴백 | ✅ 완료 |
| 패키지 내장 UI 문자열 | `Resources/Localizable.xcstrings`(String Catalog, 11개 키)를 `Bundle.module`에서 로드. 호스트 앱 번들과 무관하게 en/ko/ja 제공 | ✅ 완료 |
| L10n | 내장 문자열 접근 지점. UI 코드에 문자열 리터럴 금지 | ✅ 완료 |
| Locale+Supported | 기기 로케일을 지원 언어(en/ko/ja)로 매핑, 미지원 언어는 영어 | ✅ 완료 |

### 품질 / 인프라

| 항목 | 설명 | 상태 |
|------|------|------|
| 유닛 테스트 | swift-testing 기반 72개 테스트 (`Tests/CrossPromoKitTests/`, 7개 스위트 파일 + 공용 헬퍼 2개) | ✅ 완료 |
| CI | GitHub Actions(`.github/workflows/ci.yml`): SwiftLint, iOS 시뮬레이터 테스트, 데모 앱 빌드 | ✅ 완료 |
| SwiftLint 강제 | `swiftlint lint --strict`로 경고도 실패 처리. 버전은 `.swiftlint-version`에 핀 고정, CI가 해당 릴리스 바이너리를 내려받아 사용 | ✅ 완료 |
| Tests 린트 스코프 | `Tests/`도 린트 대상. 테스트 전용 완화는 `Tests/.swiftlint.yml` 중첩 설정으로 관리 | ✅ 완료 |
| 시뮬레이터 선택 스크립트 | `.github/scripts/select-simulator.py`로 러너의 사용 가능한 시뮬레이터를 선택 | ✅ 완료 |

### 데모 앱 (Example App)

| 기능 | 설명 | 상태 |
|------|------|------|
| Xcode 프로젝트 | iOS 17.0+, Swift 6 타겟, 로컬 패키지 의존 | ✅ 완료 |
| demo-apps.json | 5개의 가상 앱 구성 (번들 리소스, `file://`로 로드) | ✅ 완료 |
| Settings 탭 | MoreAppsView 통합 화면 | ✅ 완료 |
| Debug 탭 | 상태 테스트 및 디버그 도구 | ✅ 완료 |
| 상태 테스트 | loaded, loading, empty, error 상태 전환 | ✅ 완료 |
| 캐시 관리 | 상태 표시 및 강제 새로고침 | ✅ 완료 |
| 다국어 지원 | 영어, 한국어, 일본어 (`Resources/Localizable.xcstrings`) | ✅ 완료 |
| SKOverlay 처리 | 기기: SKOverlay / 시뮬레이터: 폴백 알림 | ✅ 완료 |
| DemoEventHandler | 콘솔 로그 이벤트 핸들러 | ✅ 완료 |

## 화면 구성

### Settings 탭
- **경로**: TabView > Settings
- **주요 기능**:
  - "More Apps" 섹션에서 MoreAppsView 표시
  - 현재 앱(PhotoMagic)을 제외한 4개 앱 표시
  - 탭하면 SKOverlay 또는 폴백 알림 표시
  - demo state에 따라 다양한 UI 상태 표시
- **상태**: ✅ 완료

### Debug 탭
- **경로**: TabView > Debug
- **주요 기능**:
  - State Testing: 데모 상태 전환 (Loaded/Loading/Empty/Error)
  - Cache: 캐시 상태 표시 및 강제 새로고침
  - Localization: 현재 언어 코드 표시
  - Demo Configuration: 현재 앱 ID 및 제외 상태 표시
- **상태**: ✅ 완료

## 데이터 모델

### PromoApp
```swift
public struct PromoApp: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let appStoreID: String
    public let iconURL: URL
    public let category: String
    public let tagline: LocalizedText
}
```

### AppCatalog
```swift
public struct AppCatalog: Codable, Sendable, Equatable {
    public let apps: [PromoApp]
    public let promoRules: [String: [String]]?   // 호스트 앱 ID → 노출 허용 앱 ID
}
```

### PromoConfig
```swift
public struct PromoConfig: Sendable, Equatable {
    public let jsonURL: URL
    public let currentAppID: String
}
```

### LocalizedText
```swift
public struct LocalizedText: Codable, Sendable, Equatable {
    public let en: String    // 필수 폴백
    public let ko: String?
    public let ja: String?
}
```

### PromoEvent
```swift
public enum PromoEvent: Sendable, Equatable {
    case impression(appID: String)
    case tap(appID: String)
}
```

### DemoState (데모 앱)
```swift
enum DemoState: String, CaseIterable, Identifiable {
    case loaded   // 로드된 앱 목록 표시
    case loading  // 로딩 인디케이터 표시
    case empty    // 빈 상태 표시
    case error    // 에러 메시지 표시
}
```

## 기술 스택

- Swift 6.0 (Strict Concurrency: complete)
- SwiftUI
- StoreKit (SKOverlay), UIKit (window scene 조회)
- Foundation (URLSession, UserDefaults), CryptoKit (캐시 키 다이제스트)
- swift-testing (테스트)
- iOS 17.0+
- 서드파티 의존성 없음

## 프로젝트 구조

```
CrossPromoKit/
├── Package.swift
├── Sources/CrossPromoKit/
│   ├── Models/
│   │   ├── AppCatalog.swift
│   │   ├── LocalizedText.swift
│   │   ├── PromoApp.swift
│   │   ├── PromoConfig.swift
│   │   └── PromoEvent.swift
│   ├── Services/
│   │   ├── AppStoreOverlayPresenter.swift
│   │   ├── CacheManager.swift
│   │   ├── NetworkClient.swift
│   │   └── PromoService.swift
│   ├── Views/
│   │   ├── Components/
│   │   │   └── AsyncAppIcon.swift
│   │   ├── EmptyStateView.swift
│   │   ├── MoreAppsView.swift
│   │   └── PromoAppRow.swift
│   ├── Design/
│   │   └── WarmEmbraceTokens.swift
│   ├── Extensions/
│   │   ├── L10n.swift
│   │   └── Locale+Supported.swift
│   ├── Protocols/
│   │   └── PromoEventDelegate.swift
│   └── Resources/
│       └── Localizable.xcstrings        # en, ko, ja
├── Tests/
│   ├── .swiftlint.yml                   # 테스트 전용 린트 완화
│   └── CrossPromoKitTests/
│       ├── CacheManagerTests.swift
│       ├── L10nTests.swift
│       ├── LocaleSupportedTests.swift
│       ├── LocalizedTextTests.swift
│       ├── MoreAppsViewInitTests.swift
│       ├── NetworkClientTests.swift
│       ├── PromoServiceTests.swift
│       ├── StubURLProtocol.swift        # 헬퍼
│       └── TestFixtures.swift           # 헬퍼
├── Example/CrossPromoDemo/
│   ├── CrossPromoDemo.xcodeproj
│   └── CrossPromoDemo/
│       ├── CrossPromoDemoApp.swift
│       ├── ContentView.swift
│       ├── SettingsView.swift
│       ├── DebugView.swift
│       ├── Helpers/
│       │   ├── DemoState.swift
│       │   ├── DemoViewModel.swift
│       │   └── DemoEventHandler.swift
│       ├── MockData/
│       │   └── demo-apps.json
│       └── Resources/
│           └── Localizable.xcstrings
├── .github/
│   ├── workflows/ci.yml                 # SwiftLint + 테스트 + 데모 앱 빌드
│   └── scripts/select-simulator.py
├── .swiftlint.yml
├── .swiftlint-version                   # CI와 로컬이 공유하는 핀 고정 버전
├── docs/images/                         # README 자산
└── specs/                               # 초기 설계 문서 (히스토리, 코드의 FR-### 참조 대상)
```

## 검증 명령

`swift build` / `swift test`는 동작하지 않습니다(iOS 전용 패키지라 macOS 호스트에서 SwiftUI/StoreKit 컴파일 실패). 시뮬레이터 대상 xcodebuild를 사용합니다.

```bash
xcodebuild test -scheme CrossPromoKit -destination 'platform=iOS Simulator,name=iPhone 17'
swiftlint lint --strict   # .swiftlint-version에 고정된 버전 사용
```

## 데모 앱 가상 앱 목록

| ID | 이름 | 카테고리 | 아이콘 (SF Symbol) |
|----|------|----------|-------------------|
| photomagic | PhotoMagic | Photo & Video | camera.filters |
| weatherpal | WeatherPal | Weather | cloud.sun.fill |
| fittrack | FitTrack | Health & Fitness | figure.run |
| noteflow | NoteFlow | Productivity | note.text |
| budgetwise | BudgetWise | Finance | dollarsign.circle.fill |

> PhotoMagic은 현재 앱으로 설정되어 목록에서 제외됨 (4개 앱 표시)

## 릴리스 상태

| 항목 | 상태 |
|------|------|
| 배포 버전 | 미출시 — git 태그 및 GitHub 릴리스 없음 |
| 기능 범위 | 위 기능 목록 전 항목 구현 완료, 시뮬레이터 테스트 통과 |
| 사용 방법 | SPM에서 브랜치/커밋 지정으로 참조 (버전 태그가 없어 버전 범위 지정 불가) |

> 첫 태그를 자를 때 이 표를 버전 히스토리로 교체합니다.

## 개발 워크플로

- GitHub 이슈 → 브랜치 → PR → main 머지. PR은 CI(SwiftLint `--strict`, 시뮬레이터 테스트, 데모 앱 빌드)를 통과해야 합니다.
- 초기 설계는 spec-kit 기반으로 진행했고 그 산출물이 `specs/001-cross-promo-kit`, `specs/002-demo-app`에 남아 있습니다. spec-kit 도구 자체는 제거되었으므로(#26) 해당 문서는 히스토리 및 코드 내 `FR-###` 참조용으로만 유지하며, 현재 작업 단위는 spec-kit 태스크가 아니라 이슈입니다.
