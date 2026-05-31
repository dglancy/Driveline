# Project: AutoRoute

## Quick Reference
- **Platform**: iOS 26+
- **Language**: Swift 6.3
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Architecture**: MVVM with @Observable
- **Minimum Deployment**: iOS 26.0
- **Package Manager**: Swift Package Manager
- **Testing**: Swift Testing (`import Testing`)
- 

## MVVM Rules

Every screen-level View **must** have a paired ViewModel:
- The ViewModel is `@Observable`, `@MainActor`, a `final class`, lives in the same folder as its View, and is named `<Screen>ViewModel`.
- The ViewModel owns **all** formatted output (dates, distances, speeds, durations) and **all** UI state (`showingSheet`, `isLoading`, etc.). The View must not call formatters or compute display strings inline.
- Tightly related private subviews (e.g. `EndpointRow`, `MetadataRow`) may live in the same file as the View; they are not screen-level and do not need their own ViewModels.
- The View creates the ViewModel in a `@State` property, initialising it from its inputs: `@State private var viewModel: FooViewModel` / `init(…) { _viewModel = State(initialValue: FooViewModel(…)) }`.

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)
- Indentation: **2 spaces**
- No trailing whitespace anywhere, including on empty lines
- One type per file (unless tightly related)
- Explicit access control where non-default (`private`, `fileprivate`)
- Avoid `public` unless strictly necessary
- Avoid force unwraps and `try!` in production code, encourage their use in tests
- Use UK English spelling over US English
- Do not write comments in generated code unless it is absolutely necessary to aid understanding
- Use `// MARK: -` sections to organise Swift types (e.g. `// MARK: - Properties`, `// MARK: - Computed Properties`, `// MARK: - Lifecycle`)
– Any hardcoded strings that are available to the UI (i.e. not Log statements) should be localisation/accessibility friendly.
- Begin every new Swift file with the standard Xcode boilerplate header, using the current date and "Damien Glancy" as the author:
  ```
  //
  //  FileName.swift
  //  AutoRoute
  //
  //  Created by Damien Glancy on DD/MM/YYYY.
  //
  ```

### SwiftUI Patterns
- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects
