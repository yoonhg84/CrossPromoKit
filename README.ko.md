# CrossPromoKit

iOS 앱 포트폴리오 내 교차 프로모션을 위한 경량 Swift SDK입니다.

**언어**: [English](README.md) | [한국어](README.ko.md)

## 개요

CrossPromoKit은 원격 JSON 카탈로그를 사용하여 iOS 앱 간 원활한 교차 프로모션을 지원합니다. SKOverlay를 통한 네이티브 App Store 통합이 포함된 바로 사용 가능한 SwiftUI 뷰를 제공합니다.

## 주요 기능

- **SwiftUI 네이티브**: 설정 화면에 바로 삽입 가능한 `MoreAppsView` 컴포넌트
- **SKOverlay 통합**: 마찰 없는 앱 발견을 위한 인앱 App Store 오버레이
- **원격 구성**: GitHub, CDN 등 어디서나 호스팅 가능한 JSON 기반 앱 카탈로그
- **3단계 폴백**: 안정성을 위한 네트워크 → 캐시 → 빈 상태 전략
- **분석 지원**: 노출 및 탭 이벤트를 위한 델리게이트 기반 이벤트 추적
- **프로모션 규칙**: 앱별 프로모션 대상을 제어하는 커스텀 규칙
- **다국어 지원**: 지역화된 태그라인 내장 지원
- **Swift 6.0**: Sendable 타입으로 완전한 엄격 동시성 준수

## 요구 사항

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## 설치

### Swift Package Manager

SPM을 통해 CrossPromoKit을 프로젝트에 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/user/CrossPromoKit.git", from: "1.0.0")
]
```

또는 Xcode에서: File → Add Package Dependencies → 저장소 URL 입력.

## 빠른 시작

### 1. 앱 카탈로그 호스팅

JSON 파일을 생성하고 호스팅하세요 (예: GitHub raw URL):

```json
{
  "apps": [
    {
      "id": "myapp1",
      "name": "My App 1",
      "appStoreID": "123456789",
      "iconURL": "https://example.com/icon1.png",
      "category": "생산성",
      "tagline": {
        "en": "Your productivity companion",
        "ko": "당신의 생산성 동반자"
      }
    },
    {
      "id": "myapp2",
      "name": "My App 2",
      "appStoreID": "987654321",
      "iconURL": "https://example.com/icon2.png",
      "category": "금융",
      "tagline": {
        "en": "Manage your finances",
        "ko": "재정을 관리하세요"
      }
    }
  ]
}
```

### 2. 설정 화면에 추가

```swift
import SwiftUI
import CrossPromoKit

struct SettingsView: View {
    var body: some View {
        List {
            // 다른 설정 항목들...

            Section("더 많은 앱") {
                MoreAppsView(currentAppID: "myapp1")
            }
        }
    }
}
```

끝입니다! 현재 앱은 목록에서 자동으로 제외됩니다.

## 고급 사용법

### 커스텀 구성

```swift
import CrossPromoKit

let config = PromoConfig(
    jsonURL: URL(string: "https://your-domain.com/apps.json")!,
    currentAppID: "myapp1"
)

MoreAppsView(config: config)
```

### 분석 연동

델리게이트로 사용자 상호작용을 추적하세요:

```swift
class AnalyticsHandler: PromoEventDelegate {
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        switch event {
        case .impression(let appID):
            // 분석 도구에 노출 이벤트 기록
            Analytics.log("promo_impression", ["app_id": appID])
        case .tap(let appID):
            // 분석 도구에 탭 이벤트 기록
            Analytics.log("promo_tap", ["app_id": appID])
        }
    }
}

// 사용법
let handler = AnalyticsHandler()
MoreAppsView(config: config, eventDelegate: handler)
```

### 프로모션 규칙

어떤 앱이 어떤 앱을 프로모션할 수 있는지 제어하세요:

```json
{
  "apps": [...],
  "promoRules": {
    "myapp1": ["myapp2", "myapp3"],
    "myapp2": ["myapp1"]
  }
}
```

이 예시에서:
- `myapp1`은 `myapp2`와 `myapp3`만 표시
- `myapp2`는 `myapp1`만 표시
- 규칙이 없는 앱은 모든 다른 앱을 표시

## API 레퍼런스

### MoreAppsView

프로모션 앱을 표시하는 메인 SwiftUI 뷰입니다.

```swift
// 간단한 초기화
MoreAppsView(currentAppID: String)

// 커스텀 구성
MoreAppsView(config: PromoConfig)

// 분석 연동
MoreAppsView(config: PromoConfig, eventDelegate: PromoEventDelegate?)
```

### PromoConfig

프로모션 서비스 구성입니다.

```swift
struct PromoConfig {
    let jsonURL: URL        // 원격 JSON 엔드포인트
    let currentAppID: String // 앱의 ID (목록에서 제외됨)
}
```

### PromoService

앱 로딩과 상호작용을 관리하는 핵심 서비스입니다.

```swift
@Observable
class PromoService {
    var apps: [PromoApp]      // 현재 필터링된 앱 목록
    var isLoading: Bool       // 로딩 상태
    var error: Error?         // 오류 상태

    func loadApps() async     // 폴백으로 로드
    func forceRefresh() async // 캐시 무시
    func handleAppTap(_ app: PromoApp)       // 오버레이 표시
    func handleAppImpression(_ app: PromoApp) // 노출 추적
}
```

### PromoEvent

서비스에서 발생하는 분석 이벤트입니다.

```swift
enum PromoEvent {
    case impression(appID: String) // 앱 행이 화면에 표시됨
    case tap(appID: String)        // 사용자가 행을 탭함
}
```

## JSON 형식

### 전체 스키마

```json
{
  "apps": [
    {
      "id": "string",           // 고유 식별자
      "name": "string",         // 표시 이름
      "appStoreID": "string",   // App Store 숫자 ID
      "iconURL": "string",      // 아이콘 HTTPS URL
      "category": "string",     // 카테고리 라벨
      "tagline": {              // 지역화된 설명
        "en": "string",
        "ko": "string"
      }
    }
  ],
  "promoRules": {               // 선택 사항
    "appId": ["허용된", "앱", "ID들"]
  }
}
```

### 참고사항

- `iconURL`은 반드시 HTTPS여야 합니다
- `tagline`은 사용자 로케일이 없으면 영어로 폴백됩니다
- 앱은 JSON 배열 순서대로 표시됩니다
- 현재 앱은 항상 자동으로 제외됩니다

## 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.

---

iOS 개발자 커뮤니티를 위해 정성껏 만들었습니다.
