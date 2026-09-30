Modernize this SwiftUI app to current Apple-recommended patterns for the latest SDK (Xcode 27 / 2027 OS releases where available). Do not rewrite the product. Preserve behavior, navigation flows, and public APIs unless an API is deprecated or incorrect.

Work in this order. Stop after each phase and show a short report before continuing.

Phase 0 — Inventory
- Deployment target, Swift version, architecture (MVVM / coordinators / other)
- List every use of: ObservableObject, @Published, @StateObject, @ObservedObject, @EnvironmentObject, NavigationView, NavigationLink(destination:), onAppear for async work, Combine for UI state, GeometryReader for sizing, UIScreen.main, idiom/orientation checks, UIKit wrappers that now have SwiftUI equivalents
- List soft-deprecated SwiftUI APIs and their replacements
- Note Liquid Glass / system chrome conflicts (custom nav bar backgrounds, hardcoded colors, UIDesignRequiresCompatibility)
- Do not edit files in this phase

Phase 1 — State and data flow
- Replace ObservableObject + @Published with @Observable classes
- Replace @StateObject with @State for owned @Observable models
- Use @Bindable only when a child needs bindings into an @Observable model
- Replace @EnvironmentObject with @Environment(Type.self)
- Mark view models @MainActor
- Use @ObservationIgnored for services, cancellables, and non-UI fields
- Do not mix ObservableObject and @Observable on the same type
- Prefer SwiftData @Model / @Query where this app already uses SwiftData; do not migrate Core Data unless I ask

Phase 2 — Concurrency and view lifetime
- Swift 6 strict concurrency: no UI mutations off the main actor
- Replace onAppear { Task { … } } with .task / .task(id:)
- Prefer async/await over Combine for new work; leave Combine only at legacy boundaries
- Cancel work with the view; no unstructured Tasks that outlive the screen unless explicitly owned

Phase 3 — Navigation and scenes
- Replace NavigationView with NavigationStack or NavigationSplitView
- Prefer value-based NavigationLink + navigationDestination(for:)
- Centralize path state if navigation is programmatic
- Use dismiss / isPresented instead of presentationMode
- Use topBarLeading / topBarTrailing instead of navigationBarLeading / Trailing
- Make layouts adaptive: size classes and container/scene bounds, never UIScreen.main or device idiom for layout

Phase 4 — UI system and Liquid Glass
- Prefer system materials and standard toolbars/tabs/sheets over custom chrome
- Adopt glassEffect / GlassEffectContainer only where custom surfaces need it
- Remove compatibility flags if present and safe
- Keep Human Interface Guidelines; do not invent a new design system

Phase 5 — Lists, identity, performance
- ForEach over stable Identifiable IDs, never indices
- Avoid unnecessary view invalidation; keep body reads narrow
- Prefer Layout / container-relative sizing over GeometryReader unless measurement is required
- Use #Preview with realistic sample data

Phase 6 — Cleanup
- Replace remaining soft-deprecated APIs from the SwiftUI specialist list
- Add accessibility identifiers/labels where you touch a view
- Do not edit .pbxproj / project.pbxproj by hand
- Do not add third-party libraries
- Run / compile after each phase and fix errors you introduced

Constraints
- Small, reviewable diffs. One concern per change set.
- If a change is too large for one pass, leave a TODO comment and move on.
- If an API requires a higher OS than our deployment target, use the newest API that fits the target and note the gap.
- After all phases, give: files changed, APIs replaced (old → new), remaining debt, and any behavior risks.
