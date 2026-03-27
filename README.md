# Squad Sports SDK Example Apps

Example applications demonstrating Squad Sports SDK integration on Android and iOS.

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/withyoursquad/squad-sdk-example-app.git
   ```

2. Copy `.env.example` to `.env` and add your credentials:
   ```bash
   cp .env.example .env
   ```
   ```
   SQUAD_PARTNER_ID=your-partner-id
   SQUAD_API_KEY=your-api-key
   ```

3. Run the app:
   - **Android**: Open `android/` in Android Studio. Set the env vars in your run configuration or add them to `android/local.properties`:
     ```properties
     SQUAD_PARTNER_ID=your-partner-id
     SQUAD_API_KEY=your-api-key
     ```
     Sync Gradle, then Run.
   - **iOS**: Open `ios/Wikipedia.xcodeproj`. Add `SQUAD_PARTNER_ID` and `SQUAD_API_KEY` to the scheme's environment variables, or add them to `Info.plist`. Resolve packages, then Run.

4. **Launch Squad**: Open the app menu and tap the Squad option.

## What the Integration Looks Like

### Android
- **Dependency**: One line in `gradle/libs.versions.toml`
- **Setup**: One call in `WikipediaApp.kt` — `SquadSportsSDK.setup(context, partnerId, apiKey)`
- **Launch**: One call in `MenuNavTabDialog.kt` — `SquadExperienceActivity.launch(context)`
- No manifest changes needed (SDK registers its own activity)
- No coroutine boilerplate (setup is fire-and-forget)

### iOS
- **Dependency**: SPM package `https://github.com/withyoursquad/squad-sports-ios.git`
- **Setup**: One call in `AppDelegate.swift` — `SquadSportsSDK.setup(partnerId:apiKey:)`
- **Launch**: `SquadSportsSDK.shared.createExperienceViewController()`

## Resources

- [SDK Documentation](https://docs.squadforsports.com)
- [iOS SDK](https://github.com/withyoursquad/squad-sports-ios)
- [Android SDK](https://github.com/withyoursquad/squad-sports-android)
