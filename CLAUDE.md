# Project: AutoRoute

## Stack
- **Platform**: iOS 26+, minimum deployment iOS 26.0
- **Language**: Swift 6.3
- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Architecture**: MVVM with `@Observable`
- **Packages**: Swift Package Manager
- **Testing**: Swift Testing (`import Testing`)

---

## MVVM

- Every screen-level View **must** have a paired `<Screen>ViewModel`.
- ViewModels are `@Observable @MainActor final class`, live in the same folder as their View.
- ViewModels own **all** formatted output (dates, distances, speeds, durations) and **all** UI state (`showingSheet`, `isLoading`, etc.). Views must not call formatters or compute display strings inline.
- Views create the ViewModel in a `@State` property: `@State private var viewModel: FooViewModel` / `init(…) { _viewModel = State(initialValue: FooViewModel(…)) }`.
- Tightly related private subviews (e.g. `EndpointRow`) may live in the same file as the View and do not need their own ViewModels.

---

## Swift Style

- Swift 6 strict concurrency throughout.
- `async/await` for all async operations — no GCD or `DispatchQueue`.
- Prefer `@Observable` over `ObservableObject`.
- Prefer value types (structs) over reference types (classes).
- Use `guard` for early exits.
- Explicit access control where non-default (`private`, `fileprivate`). Avoid `public` unless strictly necessary.
- No force unwraps or `try!` in production code; they are acceptable in tests.
- 2-space indentation. No trailing whitespace, including on blank lines.
- One type per file unless tightly related.
- Use `// MARK: -` sections to organise types: `Properties`, `Computed Properties`, `Lifecycle`, etc.
- US English spelling.
- Do not write comments in generated code unless absolutely necessary to aid understanding.
- Any hardcoded strings visible in the UI must be localisation/accessibility friendly.
- Zero warnings on compile.
- Always write new tests or update existing tests for any code change.

### File Header

Begin every new Swift file with:

```swift
//
//  FileName.swift
//  Driveline
//
//  Created by Damien Glancy on DD/MM/YYYY.
//
```

---

## SwiftUI

- Extract views exceeding 100 lines.
- `@State` for local view state only.
- `@Environment` for dependency injection.
- `NavigationStack` — never the deprecated `NavigationView`.
- `@Bindable` for bindings to `@Observable` objects.

---

## SwiftData: Cross-Actor Model Access

**Always use the ID-fetch pattern. Never pass model instances across actor boundaries.**

### Pattern

1. Extract `PersistentIdentifier` on the originating actor.
2. Pass only the identifier across the boundary — it is `Sendable`.
3. On the receiving actor, fetch the model from its own `ModelContext` via `context.model(for:)`.

```swift
// ✅ Correct
let id = trip.persistentModelID
Task.detached {
    await modelActor.process(id: id)
}

// In the @ModelActor:
func process(id: PersistentIdentifier) {
    let trip = context.model(for: id)
    // work with trip here
}

// ❌ Never
nonisolated func process(trip: sending Trip) { ... }
```

### Why
- `ModelContext` is not `Sendable`; a model is bound to the context it was fetched in. Passing instances risks context mismatch, data races, or silent staleness.
- `PersistentIdentifier` is `Sendable` and stable across contexts — it is the correct cross-actor currency.
- Use the `@ModelActor` macro for background contexts; never manage a `ModelContext` manually inside a bare `actor`.

### Applies to
- All `@ModelActor` types in this project.
- Any `Task.detached` or `async` work touching SwiftData models.
- Background import, classification, and export pipelines.

---

## Builds & Tests

- Simulator destination: `platform=iOS Simulator,name=iPhone 17`
- Never `git commit` any change.

---

## Xcode

- The project uses Xcode's File System Synchronized Groups — new files are picked up automatically, no need to add them to the project.
- Ignore and do not report stale SourceKit indexer noise.
