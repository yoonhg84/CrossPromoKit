# CrossPromoKit PRD

> 마지막 업데이트: 2026-01-19

## 개요

CrossPromoKit은 iOS 앱 간 크로스 프로모션을 위한 Swift Package입니다. 개발자가 자신의 앱 포트폴리오 내에서 다른 앱을 홍보할 수 있도록 설계되었으며, 원격 JSON 구성, 캐싱, SKOverlay 통합을 지원합니다.

## 핵심 가치

- 간편한 통합: 몇 줄의 코드로 크로스 프로모션 기능 추가
- 유연한 구성: 원격 JSON을 통한 동적 앱 목록 관리
- 다국어 지원: 영어, 한국어, 일본어 태그라인 지원
- 네이티브 경험: SKOverlay를 통한 인앱 App Store 표시

## 타겟 사용자

- 여러 앱을 보유한 iOS 개발자
- 앱 포트폴리오 내 사용자 유입을 원하는 인디 개발자
- 간단한 크로스 프로모션 솔루션을 찾는 팀

## 기능 목록

### 핵심 기능 (Core)

| 기능 | 설명 | 상태 |
|------|------|------|
| MoreAppsView | 프로모션 앱 목록을 표시하는 SwiftUI 뷰 | ✅ 완료 |
| PromoService | 데이터 로딩, 캐싱, 필터링 관리 서비스 | ✅ 완료 |
| PromoConfig | JSON URL 및 현재 앱 ID 구성 | ✅ 완료 |
| PromoApp | 프로모션 앱 데이터 모델 | ✅ 완료 |
| LocalizedText | 다국어 태그라인 지원 | ✅ 완료 |
| NetworkClient | 원격 JSON 데이터 가져오기 | ✅ 완료 |
| CacheManager | UserDefaults 기반 24시간 캐싱 | ✅ 완료 |
| SKOverlay 통합 | 인앱 App Store 오버레이 표시 | ✅ 완료 |
| PromoEventDelegate | 노출 및 탭 이벤트 위임 | ✅ 완료 |
| 3단계 폴백 | Network → Cache → Empty State | ✅ 완료 |

### UI 컴포넌트

| 기능 | 설명 | 상태 |
|------|------|------|
| PromoAppRow | 개별 앱 행 컴포넌트 | ✅ 완료 |
| AsyncAppIcon | 비동기 아이콘 로딩 (SF Symbol 지원) | ✅ 완료 |
| EmptyStateView | 빈 상태 표시 뷰 | ✅ 완료 |
| WarmEmbraceTokens | 디자인 토큰 시스템 | ✅ 완료 |

### 데모 앱 (Example App)

| 기능 | 설명 | 상태 |
|------|------|------|
| Xcode 프로젝트 | iOS 17.0+, Swift 6 타겟 | ✅ 완료 |
| demo-apps.json | 5개의 가상 앱 구성 | ✅ 완료 |
| Settings 탭 | MoreAppsView 통합 화면 | ✅ 완료 |
| Debug 탭 | 상태 테스트 및 디버그 도구 | ✅ 완료 |
| 상태 테스트 | normal, loading, empty, error 상태 전환 | ✅ 완료 |
| 캐시 관리 | 상태 표시 및 강제 새로고침 | ✅ 완료 |
| 다국어 지원 | 영어, 한국어, 일본어 (Localizable.xcstrings) | ✅ 완료 |
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
  - State Testing: 데모 상태 전환 (Normal/Loading/Empty/Error)
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
    // en, ko, ja 지원
}
```

### DemoState (데모 앱)
```swift
enum DemoState: String, CaseIterable, Identifiable {
    case normal   // 로드된 앱 목록 표시
    case loading  // 로딩 인디케이터 표시
    case empty    // 빈 상태 표시
    case error    // 에러 메시지 표시
}
```

## 기술 스택

- Swift 6.0 (Strict Concurrency: complete)
- SwiftUI
- StoreKit (SKOverlay)
- Foundation (URLSession, UserDefaults)
- iOS 17.0+

## 프로젝트 구조

```
CrossPromoKit/
├── Sources/CrossPromoKit/
│   ├── Models/
│   │   ├── AppCatalog.swift
│   │   ├── LocalizedText.swift
│   │   ├── PromoApp.swift
│   │   ├── PromoConfig.swift
│   │   └── PromoEvent.swift
│   ├── Services/
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
│   │   └── Locale+Supported.swift
│   └── Protocols/
│       └── PromoEventDelegate.swift
├── Example/CrossPromoDemo/
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
└── Tests/
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

## 버전 히스토리

| 버전 | 날짜 | 주요 변경 |
|------|------|----------|
| 1.0.0 | 2026-01-19 | 초기 구현 완료 |
| - | 2026-01-19 | 데모 앱 구현 (002-demo-app) - 42개 태스크 완료 |

## 구현 완료 사항 (002-demo-app)

### Phase 1: Xcode 프로젝트 설정
- iOS 17.0+ 타겟, Swift 6
- CrossPromoKit 로컬 패키지 의존성 추가

### Phase 2: Mock 데이터
- demo-apps.json에 5개 가상 앱 구성
- SF Symbol 기반 아이콘 URL 형식

### Phase 3: Settings 화면
- MoreAppsView 통합
- PromoConfig로 로컬 JSON 로드

### Phase 4: 상태 테스트 인프라
- DemoState enum (normal/loading/empty/error)
- DemoViewModel (@Observable)
- 상태별 UI 분기 처리

### Phase 5: Debug 화면
- State picker로 데모 상태 전환
- 캐시 상태 표시 및 강제 새로고침
- 언어 정보 표시
- 현재 앱 설정 표시

### Phase 6: 다국어 지원
- Localizable.xcstrings 생성
- 영어, 한국어, 일본어 번역 완료

### Phase 7: SKOverlay 통합
- CrossPromoKit의 SKOverlay 처리 상속
- 시뮬레이터용 폴백 알림

### Phase 8: 품질 검증
- 빌드 성공 (0 warnings)
- iOS Simulator 테스트 완료
