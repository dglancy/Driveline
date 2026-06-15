![Hero image](https://github.com/dglancy/Driveline/blob/main/hero.png)

# Driveline

[![Build & Test](https://github.com/dglancy/Driveline/actions/workflows/ios.yml/badge.svg)](https://github.com/dglancy/Driveline/actions/workflows/ios.yml)
[![CodeQL](https://github.com/dglancy/Driveline/actions/workflows/codeql.yml/badge.svg)](https://github.com/dglancy/Driveline/actions/workflows/codeql.yml)

A lightweight iOS app that records your drives in the background, then produces exportable maps and GPX files from each one. The idea is simple: connect to your car's Bluetooth and the drive starts recording automatically; disconnect and it stops. No fiddling with the phone.

## Background

Driveline grew out of a personal need. I run [Targa Trips](https://www.targatrips.com), a travel blog about driving a Porsche 911 Targa across Europe. Every post benefits from a clear, accurate route map — and the tools I tried either did too much, locked exports behind subscriptions, or produced maps that looked nothing like what I wanted. Driveline is what I built instead: a focused recorder that gets out of the way during the drive and produces clean GPX files and map images I can drop straight into a post.

## What it does

- **Automatic recording** via Apple Shortcuts and App Intents. You wire up start and stop actions to Bluetooth connect/disconnect automations in the Shortcuts app and Driveline handles the rest. CarPlay connection and disconnection events work just as well as a trigger.
- **Route list** showing all your drives grouped by date, with start and end place names, distance, and duration at a glance.
- **Route map** that plots the full drive with pinch-to-zoom once a route is finished.
- **Merge routes** to join two drives end-to-end into a single route, useful when you forget to start recording and pick it up partway through.
- **GPX export** in standard format, compatible with Strava, Komoot, or any other mapping tool that accepts GPX files.
- **PNG export** that renders a clean map snapshot with the route drawn on it, suitable for sharing.
- **Weather at departure and arrival** fetched via WeatherKit and shown on the drive detail screen, including condition, temperature, and a weather symbol. Apple Weather attribution is displayed as required.
- **Minimal recording screen** showing elapsed time. There is no live map during recording; see below for why.
- **Live Activity** on the Lock Screen and Dynamic Island showing elapsed time while a drive is in progress.
- **Spotlight search** indexes every finished drive so you can find it by name, start location, or end location directly from the iOS home screen. Tapping a result opens straight to that drive's detail view.
- **Localized** into US English, British English (also used in Australia and Ireland), French, German, and Dutch.

## Philosophy

Driveline is built in the spirit of the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy): do one thing well, produce output in standard formats, and let other tools take it from there. Doug McIlroy's [original formulation](https://harmful.cat-v.org/cat-v/unix_prog_design.pdf) put it plainly — write programs that do one thing and do it well, and write programs that work together.

The app records drives and exports them. That is all it does. The GPX files it produces are a lingua franca understood by Strava, Komoot, RideWithGPS, QGIS, and dozens of other tools. The Shortcuts integration means Driveline can sit in the middle of a larger automation: a shortcut can start a recording, hand off the resulting export to a cloud-storage action, notify you, or chain into anything else the Shortcuts app supports. The app does not need to know about any of that; it just needs to do its part cleanly.

Eric S. Raymond's [*The Art of Unix Programming*](http://www.catb.org/~esr/writings/taoup/html/ch01s06.html) describes this as the Rule of Modularity and the Rule of Composition — build simple parts connected by clean interfaces, and design programs to be connected with other programs. Driveline tries to follow both.

## Why no live map during recording?

Driveline is built to run almost entirely in the background. Rendering a live map would require keeping a large coordinate buffer in memory and continuously redrawing the UI, which is not a good trade for a drive that could last several hours. Instead, the app writes GPS points directly to the database as they arrive and renders the full map only after the drive is complete.

## Project structure

```
Driveline/
├── Driveline/                      Main app target (MVVM, SwiftUI, SwiftData)
│   ├── AppIntents/                  Shortcuts/App Intents actions (start, finish)
│   ├── AppLifecycle/                App entry point, bootstrap, environment, logging, constants, localization
│   ├── Assets.xcassets/             App icons, colors, and widget background
│   ├── Exports/                     GPX/PNG export rendering and Transferable conformances
│   ├── Extensions/                  Small extensions on Foundation/CoreLocation/MapKit types
│   ├── LiveActivity/                Live Activity attributes shared with the widget extension
│   ├── Models/                      SwiftData models: Drive, Position, Weather
│   ├── Services/                    Business logic: recording, merging, deletion, geocoding, weather, indexing
│   │   └── Sweeps/                  Background sweep services (place names, weather backfill)
│   └── UI/                          Screens, grouped by feature
│       ├── Common/                  Shared views, buttons, map content, presenters used across screens
│       ├── DriveDetail/             Drive detail and edit screens
│       ├── FullScreenMap/           Full-screen map view
│       ├── Home/                    Home/route list screen
│       ├── MergeDrives/             Merge drives screen
│       └── Recording/               In-progress recording screen
├── DriveCategoryClassifier.mlproj/ Create ML project for training the drive category classifier
├── DriveWidgetExtension/           Lock Screen / Dynamic Island Live Activity widget
├── DrivelineTests/                 Unit tests (Swift Testing), mirroring the app's folder structure
├── DrivelineUITests/               XCTest UI tests
├── MLTrainingData/                 CSV datasets used to train the drive category classifier
├── MLTrainingDataPrepTool/         Command-line tool for building ML training datasets from GPX exports
├── MLTrainingDataPrepToolTests/    Unit tests for the ML training data prep tool
└── Settings.bundle/                In-app Settings.app bundle
```

Each screen-level View has a paired `<Screen>ViewModel` living alongside it, following the MVVM conventions.

## Architecture

Driveline follows MVVM throughout, with `@Observable` view models owning all UI state and formatted output so views stay declarative. SwiftData models (`Drive`, `Position`, `Weather`) sit behind a service layer that handles recording, merging, geocoding, weather lookups, and ML classification — views and view models never touch SwiftData directly. 

Long-running background work (place name and weather backfill, drive category prediction) runs on dedicated `@ModelActor` sweep services, keeping the main actor free for UI while still operating safely on the shared persistence store. Cross-actor work follows an ID-fetch pattern: only `PersistentIdentifier` values cross actor boundaries, with each actor fetching its own models from its own `ModelContext`.

## Tech

**Language and frameworks**
- Swift 6.3 with strict concurrency throughout
- SwiftUI on iOS 26+
- SwiftData for persistence (three model types: `Drive`, `Position`, and `Weather`)

**Apple frameworks**
- CoreLocation with `allowsBackgroundLocationUpdates` and `kCLLocationAccuracyBestForNavigation`
- MapKit for route rendering and map snapshots on export
- WeatherKit for fetching weather conditions at the start and end of each drive
- AppIntents for the Shortcuts actions (start and finish)
- ActivityKit for the Live Activity shown on the Lock Screen and Dynamic Island during recording
- CoreSpotlight for indexing drives so they appear in Spotlight search
- CloudKit for iCloud sync of drives across devices
- Combine for publishing location updates through the service layer
- CoreML for on-device drive category classification

**Third-party packages (Swift Package Manager)**
- None by design.

**Development tooling**
- SwiftLint for style enforcement

**Testing**
- Swift Testing framework (`import Testing`) for unit tests
- XCTest for UI tests, with an in-memory SwiftData store to keep tests isolated

## Machine Learning

Driveline includes an on-device `DriveCategoryClassifier` CoreML model, used by `DriveClassifierService` to automatically assign each finished drive a category — `none`, `errand`, `urban`, `roadTrip`, `scenic`, or `mixed` — based on 14 computed driving statistics (distance, duration, speed averages and variance, time at high speed, stop counts, sinuosity, bearing change rate, and elevation gain/loss).

The model is trained using the `DriveCategoryClassifier.mlproj` Create ML project, with training and testing datasets stored as CSV files in `MLTrainingData/`.

Each drive stores the model version that produced its category. When a retrained model ships with a bumped `driveCategoryModelVersion`, a background sweep automatically reclassifies any drive last categorized by an older model version.

### ML training data prep tool

`MLTrainingDataPrepTool` is a small command-line tool, included as part of the Xcode project, for turning a folder of exported GPX drives into a CSV dataset suitable for training machine learning models.

It reads every `.gpx` file in an input directory and, for each drive, computes a row of summary statistics:

- Name, distance, and duration
- Average speed, mean speed, speed standard deviation, and speed variance
- Percentage of time spent above 80 km/h and the number of sustained high-speed segments
- Stop count and percentage of time stopped
- Sinuosity and bearing change rate per kilometre
- Elevation gain and loss

Results are appended to the given CSV file, writing a header row only if the file does not already exist.

**Usage**

```
MLTrainingDataPrepTool <input-directory> <output.csv>
```

Run `./build-MLTrainingDataPrepTool.sh` from the repo root to build the tool and install it to `~/bin/MLTrainingDataPrepTool` (add `~/bin` to your `PATH` if it isn't already).

## Building the iOS App

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

## Setting up Shortcuts automations

The app exposes two actions to the Shortcuts app: `Start drive` and `Finish drive`. You can trigger these from Bluetooth events, CarPlay events, or both, depending on what your car supports.

For each trigger type you want to use:

1. Open the Shortcuts app and create a new Automation.
2. Choose a connect trigger: "When I connect to a Car Bluetooth" for Bluetooth, or "CarPlay connects" for CarPlay.
3. Add the action "Start drive" from Driveline.
4. Create a second Automation using the matching disconnect trigger ("Car Bluetooth disconnects" or "CarPlay disconnects") with the "Finish drive" action.

If your car supports both Bluetooth and CarPlay, you can set up all four automations and they will each fire independently without interfering with each other.

If you stop the car and forget to end the route, Driveline will automatically finish it after a timeout period once it detects it has been paused long enough.

You can also enable an option in the Settings app that automatically reopens a recently finished route if driving resumes within a short period — useful if you are briefly interrupted and want to keep the drive as a single continuous record.

## License

MIT. See [LICENSE](LICENSE).
