# Quickstart: CrossPromoKit Demo App

**Feature Branch**: `002-demo-app`
**Date**: 2026-01-19

## Prerequisites

- Xcode 16.0+
- iOS 17.0+ Simulator or Device
- macOS Sonoma or later

## Running the Demo

### Step 1: Clone the Repository

```bash
git clone https://github.com/user/CrossPromoKit.git
cd CrossPromoKit
```

### Step 2: Open the Example Project

```bash
open Example/CrossPromoDemo/CrossPromoDemo.xcodeproj
```

### Step 3: Build and Run

1. Select a simulator (iPhone 15 Pro recommended)
2. Press `Cmd + R` or click the Run button
3. The demo app will launch showing the PhotoMagic demo

## Demo Features

### Main Tab (Settings)

The Settings tab demonstrates the `MoreAppsView` integration:

- **More Apps Section**: Shows 4 promotional apps (PhotoMagic excluded as current app)
- **Tap Behavior**:
  - On device: Opens SKOverlay
  - On simulator: Shows fallback alert
- **Event Logging**: Check Xcode console for impression/tap events

### State Testing

Use the debug menu to test different UI states:

1. Open the Demo app
2. Navigate to Settings → Debug Options
3. Select a state:
   - **Normal**: Default loaded state
   - **Loading**: Shows loading indicator
   - **Empty**: Shows empty state view
   - **Error**: Shows error message

### Localization Testing

Test different languages:

1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select Run → Options → App Language
3. Choose: English, Korean, or Japanese
4. Run the app

## Screenshot Capture

For README documentation, capture these screenshots:

### Hero Screenshot (Normal State)
1. Set device to iPhone 15 Pro
2. Navigate to Settings tab
3. Ensure "More Apps" section is visible
4. Capture with `Cmd + S` in Simulator

### State Screenshots
1. Use debug menu to set each state
2. Capture: Loading, Empty, Error states

### Localization Screenshots
1. Set App Language to Korean/Japanese
2. Capture the Settings screen

## Project Structure

```
Example/
└── CrossPromoDemo/
    ├── CrossPromoDemo.xcodeproj
    └── CrossPromoDemo/
        ├── CrossPromoDemoApp.swift    # App entry point
        ├── ContentView.swift          # Tab-based main view
        ├── SettingsView.swift         # Integration example
        ├── DebugOptionsView.swift     # State testing UI
        ├── MockData/
        │   └── demo-apps.json         # Bundled mock data
        └── Helpers/
            └── DemoEventHandler.swift # Event delegate demo
```

## Key Code Snippets

### Basic Integration

```swift
// SettingsView.swift
import SwiftUI
import CrossPromoKit

struct SettingsView: View {
    var body: some View {
        List {
            Section("More Apps") {
                MoreAppsView(currentAppID: "photomagic")
            }
        }
    }
}
```

### Event Handling

```swift
// DemoEventHandler.swift
class DemoEventHandler: PromoEventDelegate {
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        switch event {
        case .impression(let appID):
            print("📊 Impression: \(appID)")
        case .tap(let appID):
            print("👆 Tap: \(appID)")
        }
    }
}
```

### Custom Configuration

```swift
// Using bundled JSON
let config = PromoConfig(
    jsonURL: Bundle.main.url(forResource: "demo-apps", withExtension: "json")!,
    currentAppID: "photomagic"
)

MoreAppsView(config: config, eventDelegate: handler)
```

## Troubleshooting

### Build Errors

**"Cannot find 'CrossPromoKit' in scope"**
- Ensure the local package is added to the project
- File → Add Package Dependencies → Add Local → Select CrossPromoKit root

**"Minimum deployment target is iOS 17.0"**
- Update the Example project deployment target to iOS 17.0+

### Runtime Issues

**SKOverlay doesn't appear**
- This is expected on simulator
- Test on a physical device for actual App Store overlay

**Empty app list**
- Check that `demo-apps.json` is included in target membership
- Verify the JSON format is valid

## Next Steps

After running the demo successfully:

1. Review the integration code in `SettingsView.swift`
2. Examine the event handling in `DemoEventHandler.swift`
3. Copy the pattern to your own app
4. Replace mock JSON URL with your remote endpoint
