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

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)
- Indentation: **2 spaces**
- No trailing whitespace
- One type per file (unless tightly related)
- Explicit access control where non-default (`private`, `fileprivate`)
- Avoid `public` unless strictly necessary
- Avoid force unwraps and `try!` in production code, encourage their use in tests
- Use UK English spelling over US English

### SwiftUI Patterns
- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects
