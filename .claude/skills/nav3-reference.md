# Navigation 3 Reference (KMP-native)

Source: https://github.com/terrakok/nav3-recipes
Docs: https://developer.android.com/guide/navigation/navigation3

> **Status**: `1.0.0-alpha06` — experimental, API may change

---

## Dependencies

### Android-only (stable)

```toml
# gradle/libs.versions.toml
[versions]
nav3 = "1.0.1"
lifecycle-nav3 = "2.11.0-alpha01"

[libraries]
nav3-ui = { module = "androidx.navigation3:navigation3-ui", version.ref = "nav3" }
lifecycle-viewmodel-nav3 = { module = "androidx.lifecycle:lifecycle-viewmodel-navigation3", version.ref = "lifecycle-nav3" }
```

```kotlin
// composeApp/build.gradle.kts
androidMain.dependencies {
    implementation(libs.nav3.ui)
    implementation(libs.lifecycle.viewmodel.nav3)
}
```

### KMP — Android + Desktop + iOS + Web (alpha, JetBrains fork)

```toml
# gradle/libs.versions.toml
[versions]
nav3-kmp = "1.0.0-alpha06"
lifecycle-kmp = "2.10.0-alpha07"
navigation3-browser = "0.3.1"      # Web only (community)

[libraries]
nav3-ui = { module = "org.jetbrains.androidx.navigation3:navigation3-ui", version.ref = "nav3-kmp" }
lifecycle-viewmodel-nav3 = { module = "org.jetbrains.androidx.lifecycle:lifecycle-viewmodel-navigation3", version.ref = "lifecycle-kmp" }
navigation3-browser = { module = "com.github.terrakok:navigation3-browser", version.ref = "navigation3-browser" }
```

```kotlin
// composeApp/build.gradle.kts — commonMain block
commonMain.dependencies {
    implementation(libs.nav3.ui)
    implementation(libs.lifecycle.viewmodel.nav3)
    // Web only — add in webMain block:
    // implementation(libs.navigation3.browser)
}
```

**Imports:** `androidx.navigation3.runtime.*`, `androidx.navigation3.ui.*`

---

## Pattern 1: Basic NavDisplay (no state save)

Routes are plain data objects/classes — no string routes.

```kotlin
private data object RouteA
private data class RouteB(val id: String)

@Composable
fun AppNav() {
    val backStack = remember { mutableStateListOf<Any>(RouteA) }

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = { key ->
            when (key) {
                is RouteA -> NavEntry(key) {
                    RouteAScreen(onNavigate = { backStack.add(RouteB("123")) })
                }
                is RouteB -> NavEntry(key) {
                    RouteBScreen(id = key.id, onBack = { backStack.removeLastOrNull() })
                }
                else -> error("Unknown route: $key")
            }
        }
    )
}
```

---

## Pattern 2: DSL entryProvider syntax

```kotlin
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider = entryProvider {
        entry<RouteA> {
            RouteAScreen(onNavigate = { backStack.add(RouteB("123")) })
        }
        entry<RouteB> { key ->
            RouteBScreen(id = key.id)
        }
    }
)
```

---

## Pattern 3: Saveable backstack (survives process death)

Required: routes implement `NavKey` + `@Serializable` + register in `SerializersModule`.

```kotlin
@Serializable private data object RouteA : NavKey
@Serializable private data class RouteB(val id: String) : NavKey

private val config = SavedStateConfiguration {
    serializersModule = SerializersModule {
        polymorphic(NavKey::class) {
            subclass(RouteA::class, RouteA.serializer())
            subclass(RouteB::class, RouteB.serializer())
        }
    }
}

@Composable
fun AppNav() {
    val backStack = rememberNavBackStack(config, RouteA)   // survives rotation & process death

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = entryProvider {
            entry<RouteA> { RouteAScreen(...) }
            entry<RouteB> { key -> RouteBScreen(key.id) }
        }
    )
}
```

---

## Pattern 4: ViewModel per NavEntry

Requires `rememberViewModelStoreNavEntryDecorator()` — each NavEntry gets its own ViewModelStore.

```kotlin
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),   // saves Composable state
        rememberViewModelStoreNavEntryDecorator()          // scopes VM to NavEntry
    ),
    entryProvider = entryProvider {
        entry<RouteB> { key ->
            // ViewModel is unique per RouteB instance thanks to ViewModelStoreNavEntryDecorator
            val vm: RouteBViewModel = viewModel(factory = RouteBViewModel.Factory(key))
            RouteBScreen(vm)
        }
    }
)

class RouteBViewModel(val key: RouteB) : ViewModel() {
    class Factory(private val key: RouteB) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: KClass<T>, extras: CreationExtras): T =
            RouteBViewModel(key) as T
    }
}
```

---

## Pattern 5: Multiple stacks (BottomBar navigation)

```kotlin
@Serializable data object RouteA : NavKey
@Serializable data object RouteB : NavKey

val config = SavedStateConfiguration {
    serializersModule = SerializersModule {
        polymorphic(NavKey::class) {
            subclass(RouteA::class, RouteA.serializer())
            subclass(RouteB::class, RouteB.serializer())
        }
    }
}

private val TOP_LEVEL_ROUTES = listOf(RouteA, RouteB)

@Composable
fun AppNav() {
    val navigationState = rememberNavigationState(
        startRoute = RouteA,
        topLevelRoutes = TOP_LEVEL_ROUTES
    )
    val navigator = remember { Navigator(navigationState) }

    val entryProvider = entryProvider {
        entry<RouteA> { FeatureAScreen(onNavigate = { navigator.navigate(RouteB) }) }
        entry<RouteB> { FeatureBScreen() }
    }

    Scaffold(bottomBar = {
        NavigationBar {
            TOP_LEVEL_ROUTES.forEach { route ->
                NavigationBarItem(
                    selected = route == navigationState.topLevelRoute,
                    onClick = { navigator.navigate(route) },
                    icon = { /* icon */ },
                    label = { Text(route.toString()) }
                )
            }
        }
    }) { padding ->
        NavDisplay(
            entries = navigationState.toEntries(entryProvider),
            onBack = { navigator.goBack() },
            modifier = Modifier.padding(padding)
        )
    }
}
```

---

## Pattern 6: Conditional navigation (auth guard)

```kotlin
private data object Home
private data object Profile : AppBackStack.RequiresLogin
private data object Login

@Composable
fun AppNav() {
    val appBackStack = remember { AppBackStack(startRoute = Home, loginRoute = Login) }

    NavDisplay(
        backStack = appBackStack.backStack,
        onBack = { appBackStack.remove() },
        entryProvider = entryProvider {
            entry<Home> { HomeScreen(onProfileClick = { appBackStack.add(Profile) }) }
            entry<Profile> { ProfileScreen(onLogout = { appBackStack.logout() }) }
            entry<Login> { LoginScreen(onLogin = { appBackStack.login() }) }
        }
    )
}
// AppBackStack intercepts RequiresLogin routes and redirects to Login if not authenticated
```

---

## Nav2 vs Nav3 Comparison

| | Nav2 (Jetpack Navigation) | Nav3 (Navigation 3) |
|---|---|---|
| KMP | ❌ Android-only | ✅ Android + JVM + iOS + Web |
| Routes | String routes / `@Serializable` sealed | Data objects/classes |
| API | `NavHost` + `NavController` | `NavDisplay` + `mutableStateListOf` |
| State save | Automatic | `rememberNavBackStack()` + `NavKey` |
| ViewModel | `koinViewModel()` or `viewModel()` | `viewModel()` + `rememberViewModelStoreNavEntryDecorator()` |
| Stability | Stable (2.9.0) | Alpha (1.0.0-alpha06) |
| Koin integration | `koinViewModel()` direct | Manual factory or Koin `viewModel { }` |

---

## Web integration (Desktop + Browser)

For Web target — add `BrowserIntegration` expect/actual:

```kotlin
// commonMain
@Composable
internal expect fun BrowserIntegration()

// webMain — uses navigation3-browser
@Composable
internal actual fun BrowserIntegration() {
    // Deep link + browser history integration
}

// jvmMain — no-op
@Composable
internal actual fun BrowserIntegration() {}
```
