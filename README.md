![Hero image](https://github.com/dglancy/AutoRoute/blob/main/hero.png)

# AutoRoute

A lightweight iOS app that records your drives in the background and saves them as GPX files. The idea is simple: connect to your car's Bluetooth and the drive starts recording automatically; disconnect and it stops. No fiddling with the phone.

## What it does

- **Automatic recording** via Apple Shortcuts — trigger start, pause, and stop from Bluetooth connect/disconnect events
- **GPX export** — every route is saved as a standard GPX file you can share with any mapping app
- **Route list** — all your drives in one place, grouped by date, with distance and duration at a glance
- **Route map** — tap any route to see the full drive plotted on a map with pinch-to-zoom
- **Merge routes** — select two routes and join them end-to-end into a single route
- **Minimal recording screen** — shows elapsed time and distance while recording; no live map by design (keeps CPU and memory low for long drives)

## Why no live map during recording?

AutoRoute is built to run almost entirely in the background. Rendering a live map would require keeping a large coordinate buffer in memory and updating the UI continuously — neither of which makes sense for a drive that could last all day. Instead, the app writes GPS points directly to SwiftData as they arrive and renders the full route map only once the drive is complete.

## Tech

- iOS 26+
- Swift 6 / SwiftUI
- SwiftData for persistence
- MVVM with `@Observable`
