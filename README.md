# Inara Meditation (iOS, SwiftUI)

A minimal SwiftUI meditation app featuring a smooth card → detail transition using matchedGeometryEffect, an audio player with soundscape and narrations, and a simple bottom sheet for volume controls.

## Requirements
- Xcode 15+
- iOS 17+ (deployment target adjustable)

## Getting Started
1. Open the project in Xcode.
2. Set a unique Bundle Identifier in Targets → inara → Signing & Capabilities.
3. Enable Automatic Signing with your Apple ID/team.
4. Select a simulator or device and Run.

## Animations You Can Tweak
- File: 
  -  / : card expand/collapse timing (matched geometry).
  - : background list fade duration.
  - : delay before deselecting to complete collapse.
- File: 
  - : delay before detail content fades in after expand.
  - : fade-in/out duration for detail content.

## TestFlight (Manual)
1. In App Store Connect, create a new app with this Bundle ID.
2. In Xcode: Product → Archive, then upload via Organizer to TestFlight.
3. Add internal testers and distribute.

## Notes
- Audio files are loaded from  with fallback paths; adjust as needed.
- UI colors are defined in  and  helpers.

## License
TBD
