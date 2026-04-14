# Skill: Refactoring KMP Compose Navigation

## Trigger
Use this skill when refactoring a KMP or Android Compose project to Navigation 3.
- **Nav3 Android** (`androidx.navigation3`) — stable 1.0.1, Android-only package
- **Nav3 KMP** (`org.jetbrains.androidx.navigation3`) — alpha, Android + JVM Desktop + iOS + Web
- Stack: Koin 4.0.4. NOT Kodein/Hilt/Decompose. NOT Nav2 (deprecated direction).

**Reference files:**
- `~/.claude/skills/nav3-reference.md` — Nav3 code patterns and API

---

## Decision Tree

### Which Nav3 artifact to use?

| Situation | Artifact | Version |
|---|---|---|
| Android-only project | `androidx.navigation3:navigation3-ui` | `1.0.1` (stable) |
| KMP (Android + Desktop/iOS/Web) | `org.jetbrains.androidx.navigation3:navigation3-ui` | `1.0.0-alpha06` (alpha) |
| Already on custom backstack, Android-only | Migrate to Android nav3 stable | `1.0.1` |
| New KMP project | JetBrains fork | `1.0.0-alpha06` |

### Android nav3 or KMP nav3?

```
Does the project target Desktop JVM / iOS / Web?
  YES → KMP nav3: org.jetbrains.androidx.navigation3:navigation3-ui:1.0.0-alpha06
  NO  → Android nav3: androidx.navigation3:navigation3-ui:1.0.1 (stable!)
```

### How to pass arguments?

- **Nav2**: primitives via `NavType` in route, complex objects via Koin ViewModel + repo
- **Nav3**: data class routes carry args directly (`RouteB(id = "123")`) — no string encoding needed

### Where to store state?

- **UI state** → ViewModel (scoped to NavEntry/NavBackStackEntry)
- **Global state** → singleton in Koin

---

## Nav3: Quick Setup (see nav3-reference.md for full patterns)

**Android-only:** `androidx.navigation3:navigation3-ui:1.0.1`
**KMP:** `org.jetbrains.androidx.navigation3:navigation3-ui:1.0.0-alpha06`

```toml
# libs.versions.toml — Android-only
[versions]
nav3 = "1.0.1"
lifecycle-viewmodel-nav3 = "2.11.0-alpha01"   # lifecycle-viewmodel-navigation3

[libraries]
nav3-ui = { module = "androidx.navigation3:navigation3-ui", version.ref = "nav3" }
lifecycle-viewmodel-nav3 = { module = "androidx.lifecycle:lifecycle-viewmodel-navigation3", version.ref = "lifecycle-viewmodel-nav3" }
```

```toml
# libs.versions.toml — KMP (JetBrains fork)
[versions]
nav3-kmp = "1.0.0-alpha06"
lifecycle-kmp = "2.10.0-alpha07"

[libraries]
nav3-ui = { module = "org.jetbrains.androidx.navigation3:navigation3-ui", version.ref = "nav3-kmp" }
lifecycle-viewmodel-nav3 = { module = "org.jetbrains.androidx.lifecycle:lifecycle-viewmodel-navigation3", version.ref = "lifecycle-kmp" }
```

```kotlin
// Routes — typed data objects/classes, no string routes
private data object RouteA
private data class RouteB(val id: String)

// NavDisplay replaces NavHost/mutableStateListOf+when
val backStack = remember { mutableStateListOf<Any>(RouteA) }
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider = entryProvider {
        entry<RouteA> { RouteAScreen(onNavigate = { backStack.add(RouteB("123")) }) }
        entry<RouteB> { key -> RouteBScreen(id = key.id) }
    }
)
```

See `nav3-reference.md` for: saveable backstack, ViewModel integration, multiple stacks, conditional nav, Web support.

---

## Koin Integration

Nav3 uses `viewModel()` with factory. Koin `viewModel { }` module stays unchanged.

```kotlin
// entryDecorators — required for scoped ViewModels!
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator()   // ← without this, VM won't be per-entry
    ),
    entryProvider = entryProvider {
        entry<RouteFeature> { key ->
            val vm: FeatureViewModel = viewModel(factory = FeatureViewModel.Factory(key))
            FeatureScreen(vm)
        }
    }
)

// Koin module — unchanged
val featureModule = module {
    viewModel { FeatureViewModel(get()) }
}
```

---

## Anti-Patterns

- ❌ Forgetting `rememberViewModelStoreNavEntryDecorator()` — ViewModel won't be scoped to NavEntry
- ❌ Not adding `NavKey` + `@Serializable` with `rememberNavBackStack()` — state won't be restored
- ❌ Using string routes — Nav3 uses typed data objects/classes
- ❌ `kodein { ... }` — project uses Koin 4.0.4
- ❌ `single { MyViewModel(...) }` — always use `viewModel { }` for ViewModels
- ❌ Navigation calls (`backStack.add/remove`) in ViewModel — navigation stays in Composable
- ❌ Leaving `mutableStateListOf<AppScreen>` + when alongside NavDisplay

---

## Migration Checklist

### mutableStateListOf<AppScreen> → Nav3 Android (stable)

- [ ] Add `androidx.navigation3:navigation3-ui:1.0.1` to `libs.versions.toml` (androidMain)
- [ ] Convert `AppScreen` sealed class to data objects/classes (+ `NavKey` + `@Serializable` if state save needed)
- [ ] Replace `when(backStack.last())` block with `NavDisplay { entryProvider { entry<RouteX> { } } }`
- [ ] Add `entryDecorators` if ViewModels are used
- [ ] `App.kt`: remove `mutableStateListOf<AppScreen>` + when → `NavDisplay`
- [ ] Koin modules: unchanged (`viewModel { }` stays)
- [ ] Back-handling: Nav3 calls `onBack` lambda (managed manually — `backStack.removeLastOrNull()`)

### mutableStateListOf<AppScreen> → Nav3 KMP (alpha)

- [ ] Add `org.jetbrains.androidx.navigation3:navigation3-ui:1.0.0-alpha06` to `commonMain`
- [ ] For Web: add `navigation3-browser:0.3.1` + `expect/actual BrowserIntegration`
- [ ] All other steps — same as Android stable above
