# Project: Driveline

## Stack
- **Platform**: iOS 26+, minimum deployment iOS 26.0
- **Language**: Swift 6.3
- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Architecture**: Apple-native SwiftUI
- **Packages**: Swift Package Manager
- **Testing**: Swift Testing (`import Testing`)

---

## Architecture

### Data flow

**`@Query` for live data.** Views that display persisted models fetch them directly
with `@Query`. Do not pipe `@Query` results through an intermediate object.

**`@State` for local UI state.** Search text, sheet visibility flags, selection sets,
navigation paths, and scope toggles live as `@State` properties in the View that owns
them.

**`@Environment` for shared services and context.**
- `@Environment(\.modelContext)` for SwiftData writes.
- `@Environment(SomeService.self)` for `@Observable` services injected at app root.
- Never thread long-lived services through `init` parameters across multiple view layers;
  inject them at app root via `.environment()` and read them where needed.

**Computed properties for derived state.** Filtered lists, grouped sections, and
aggregated stats are computed properties on the View that read from `@Query` and
`@State`. SwiftUI's observation system re-evaluates them automatically when their
inputs change. No `onChange` bridge is needed.

### Formatting

Views must not call formatters or build display strings inline. Use dedicated presenter
types for all formatted output and pass the resulting strings into subviews as plain
`String` or `String?` parameters.

Presenter types in this project:
- `DriveStatsPresenter(drive:)` — formats per-drive distance, duration, speed, time.
- `DriveRowDisplay` — formatted strings for a single list row.
- `DriveDetailPresenter(drive:)` — formats all strings for the drive detail screen.
- `HomePresenter` — static label and confirmation-message strings for the home screen.
- `RecordingStatsPresenter(driveService:)` — snapshots and formats live recording stats.
- `MergeDrivesPresenter(drives:)` — formats merge-preview strings and combined totals.

### Extracted subviews

Extract views exceeding 100 lines. Tightly related private subviews may live in the
same file as their parent and do not need their own logic objects.

SwiftLint enforces a 250-line limit on type bodies (excluding comments and whitespace).
Stay under this by extracting private `View` or `ToolbarContent` structs into the same
file — they don't count toward the parent type's body length.

### When to extract a separate `@Observable` object

Extract a `@MainActor @Observable final class` when one or more of the following apply:

1. **Async state that changes independently of the view's inputs** — an ongoing async
   task, live timer, or streaming location updates (e.g. `DriveDetailModel`,
   `FullScreenMapModel`).
2. **State shared across multiple views** that are not in a direct parent-child
   relationship.
3. **A meaningful precondition or invariant at construction time** that benefits from
   encapsulation.
4. **App-scope lifetime** — these belong in the environment, not per-screen.

If none of these apply, keep state in the View.

When a model class needs `ModelContainer` at construction time, `@Environment` cannot
be read inside `init`. Pass `modelContainer` as an `init` parameter and store the model
in `@State`:

```swift
init(drive: Drive, modelContainer: ModelContainer) {
  _model = State(initialValue: DriveDetailModel(drive: drive, modelContainer: modelContainer))
}
```

The calling view reads `modelContext.container` from its own `@Environment(\.modelContext)`
and passes it through.

### Pure logic types

Stateless transformation logic with no SwiftUI dependency lives in value-type namespaces.
Test these with plain inputs — no View or SwiftData container needed.

Use a caseless `enum` (not a `struct`) for namespaces of static functions — it is
uninhabitable by design, making it clear the type is not meant to be instantiated.

Examples: `DriveSectionBuilder`, `DriveStats`, `DriveEditor`, `DriveDeletion`, `DriveMerge`.

---

## Swift Style

- Swift 6 strict concurrency throughout.
- `async/await` for all async operations — no GCD or `DispatchQueue`.
- Prefer `@Observable` over `ObservableObject`.
- Prefer value types (structs) over reference types (classes).
- Use `guard` for early exits.
- Explicit access control where non-default (`private`, `fileprivate`). Avoid `public`
  unless strictly necessary.
- No force unwraps or `try!` in production code; they are acceptable in tests.
- 2-space indentation. No trailing whitespace, including on blank lines.
- One type per file unless tightly related.
- Use `// MARK: -` sections to organise types: `Properties`, `Computed Properties`,
  `Lifecycle`, etc.
- US English spelling for code.
- Do not write comments in generated code unless absolutely necessary to aid
  understanding.
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
- @State for local view state.
- @Environment for dependency injection.
- NavigationStack — never the deprecated NavigationView.
- @Bindable for bindings to @Observable objects.

---
## SwiftData: Saving

Never call `modelContext.save()` directly. All saves go through the
`ModelContext.saveChanges(_:)` extension in `Extensions/ModelContext+Saving.swift`, which
guards on `hasChanges`, logs any failure under `Log.data`, and returns a `Bool` indicating
success (the result is `@discardableResult`). It is `nonisolated`, so both `@MainActor` and
`@ModelActor` callers use the same method.

```swift
modelContext.saveChanges("weather sweep")            // logs failure, ignores result
if modelContext.saveChanges() { clearPendingFlag() } // act on success
```

Pass an optional operation label to give the log message context. Save failures are logged,
never surfaced to the user or propagated as `throws`.

## SwiftData: Cross-Actor Model Access

Always use the ID-fetch pattern. Never pass model instances across actor boundaries.

### Pattern

1. Extract PersistentIdentifier on the originating actor.
2. Pass only the identifier across the boundary — it is Sendable.
3. On the receiving actor, fetch the model from its own ModelContext via
context.model(for:).

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

### Why

- ModelContext is not Sendable; a model is bound to the context it was fetched in.
Passing instances risks context mismatch, data races, or silent staleness.
- PersistentIdentifier is Sendable and stable across contexts — it is the correct
cross-actor currency.
- Use the @ModelActor macro for background contexts; never manage a ModelContext
manually inside a bare actor.

Applies to

- All @ModelActor types in this project.
- Any Task.detached or async work touching SwiftData models.
- Background import, classification, and export pipelines.

Injecting Collaborators into @ModelActor Types

The @ModelActor macro owns init(modelContainer:), so it can't take extra init
parameters. Inject collaborators as actor-isolated private var properties with
production defaults, overridden in tests via an async configure(...) method:

@ModelActor
actor WeatherSweepService: SweepServiceProtocol {
  private var weatherService: any WeatherFetchServiceProtocol = WeatherFetchService()

  func configure(weatherService: any WeatherFetchServiceProtocol) {
    self.weatherService = weatherService
  }

  func sweep() async { … }
}

---
## Builds & Tests

- Simulator destination: platform=iOS Simulator,name=iPhone 17
- Never git commit any change.

---
## Xcode

- The project uses Xcode's File System Synchronized Groups — new files are picked up
automatically, no need to add them to the project.
- Ignore and do not report stale SourceKit indexer noise.
