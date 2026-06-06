![Hero image](https://github.com/dglancy/Driveline/blob/main/hero.png)

# Driveline

[![Build & Test](https://github.com/dglancy/Driveline/actions/workflows/ios.yml/badge.svg)](https://github.com/dglancy/Driveline/actions/workflows/ios.yml)
[![CodeQL](https://github.com/dglancy/Driveline/actions/workflows/codeql.yml/badge.svg)](https://github.com/dglancy/Driveline/actions/workflows/codeql.yml)

A lightweight iOS app that records your drives in the background, then produces exportable maps and GPX files from each one. The idea is simple: connect to your car's Bluetooth and the drive starts recording automatically; disconnect and it stops. No fiddling with the phone.

## Background

Driveline grew out of a personal need. I run [Targa Trips](https://www.targatrips.com), a travel blog about driving a Porsche 911 Targa across Europe. Every post benefits from a clear, accurate route map — and the tools I tried either did too much, locked exports behind subscriptions, or produced maps that looked nothing like what I wanted. Driveline is what I built instead: a focused recorder that gets out of the way during the drive and produces clean GPX files and map images I can drop straight into a post.

## What it does

- **Automatic recording** via Apple Shortcuts and App Intents. You wire up start and pause actions to Bluetooth connect/disconnect automations in the Shortcuts app and Driveline handles the rest. CarPlay connection and disconnection events work just as well as a trigger.
- **Route list** showing all your drives grouped by date, with start and end place names, distance, and duration at a glance.
- **Route map** that plots the full drive with pinch-to-zoom once a route is finished.
- **Merge routes** to join two drives end-to-end into a single route, useful when you forget to start recording and pick it up partway through.
- **GPX export** in standard format, compatible with Strava, Komoot, or any other mapping tool that accepts GPX files.
- **PNG export** that renders a clean map snapshot with the route drawn on it, suitable for sharing.
- **Minimal recording screen** showing elapsed time. There is no live map during recording; see below for why.
- **Live Activity** on the Lock Screen and Dynamic Island showing elapsed time while a drive is in progress.
- **Localised** into English, French, German, and Dutch.

## Philosophy

Driveline is built in the spirit of the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy): do one thing well, produce output in standard formats, and let other tools take it from there. Doug McIlroy's [original formulation](https://harmful.cat-v.org/cat-v/unix_prog_design.pdf) put it plainly — write programs that do one thing and do it well, and write programs that work together.

The app records drives and exports them. That is all it does. The GPX files it produces are a lingua franca understood by Strava, Komoot, RideWithGPS, QGIS, and dozens of other tools. The Shortcuts integration means Driveline can sit in the middle of a larger automation: a shortcut can start a recording, hand off the resulting export to a cloud-storage action, notify you, or chain into anything else the Shortcuts app supports. The app does not need to know about any of that; it just needs to do its part cleanly.

Eric S. Raymond's [*The Art of Unix Programming*](http://www.catb.org/~esr/writings/taoup/html/ch01s06.html) describes this as the Rule of Modularity and the Rule of Composition — build simple parts connected by clean interfaces, and design programs to be connected with other programs. Driveline tries to follow both.

## Setting up Shortcuts automations

The app exposes two actions to the Shortcuts app: `Start or resume route` and `Pause route`. You can trigger these from Bluetooth events, CarPlay events, or both, depending on what your car supports.

For each trigger type you want to use:

1. Open the Shortcuts app and create a new Automation.
2. Choose a connect trigger: "When I connect to a Car Bluetooth" for Bluetooth, or "CarPlay connects" for CarPlay.
3. Add the action "Start or resume route" from Driveline.
4. Create a second Automation using the matching disconnect trigger ("Car Bluetooth disconnects" or "CarPlay disconnects") with the "Pause route" action.

If your car supports both Bluetooth and CarPlay, you can set up all four automations and they will each fire independently without interfering with each other.

If you stop the car and forget to end the route, Driveline will automatically finish it after a timeout period once it detects it has been paused long enough.

You can also enable an option in the Settings app that automatically reopens a recently finished route if driving resumes within a short period — useful if you are briefly interrupted and want to keep the drive as a single continuous record.


## Why no live map during recording?

Driveline is built to run almost entirely in the background. Rendering a live map would require keeping a large coordinate buffer in memory and continuously redrawing the UI, which is not a good trade for a drive that could last several hours. Instead, the app writes GPS points directly to the database as they arrive and renders the full map only after the drive is complete.

## Tech

**Language and frameworks**
- Swift 6.3 with strict concurrency throughout
- SwiftUI on iOS 26+
- SwiftData for persistence (two model types: `Drive` and `Position`)

**Apple frameworks**
- CoreLocation with `allowsBackgroundLocationUpdates` and `kCLLocationAccuracyBestForNavigation`
- MapKit for route rendering and map snapshots on export
- AppIntents for the Shortcuts actions (start/resume and pause)
- ActivityKit for the Live Activity shown on the Lock Screen and Dynamic Island during recording
- CloudKit for iCloud sync of drives across devices
- Combine for publishing location updates through the service layer
- Network framework (via `NWPathMonitor`) for detecting connectivity changes used to retry failed reverse geocoding

**Third-party packages (Swift Package Manager)**
- None by design.

**Development tooling**
- SwiftLint for style enforcement

**Testing**
- Swift Testing framework (`import Testing`) for unit tests
- XCTest for UI tests, with an in-memory SwiftData store to keep tests isolated

## Building it yourself

**Requirements**

- Xcode 26 or later (the project targets iOS 26.0)
- A physical iPhone for any testing that involves background location or Shortcuts automations. The simulator does not support background location in a meaningful way.

**Steps**

1. Clone the repository:
   ```
   git clone https://github.com/dglancy/Driveline.git
   ```

2. Open `Driveline.xcodeproj` in Xcode.

3. Select your development team under **Signing & Capabilities** for the `Driveline` target. The bundle identifier is `com.targatrips.Driveline`; you can change it to match your own prefix if you prefer.

4. Build and run on a connected device. The first launch will ask for location permission; choose "Always Allow" so recording works when the screen is off.

## Licence

MIT. See [LICENSE](LICENSE).
