# SpaceFlightNews

An iOS app that consumes the [Spaceflight News API](https://api.spaceflightnewsapi.net/v4/) and displays a paginated, searchable list of space-related articles.

Built as a technical challenge with a focus on clean architecture, testability, and zero external dependencies.

---

## Screenshots

<!-- Add screenshots here: article list, error state, empty search, article detail, splash -->
### Success screens

| Splash | Home | Detail | Empty news | Empty search |
|---|---|---|---|---|
| <img width="1206" height="2622" alt="image" src="https://github.com/user-attachments/assets/e77bc84e-5cd3-49d9-8658-3395c9a7b39a" /> | <img width="1206" height="2622" alt="image" src="https://github.com/user-attachments/assets/4aa1f1b1-db66-4c8d-9770-3a3953f5fa3b" /> | <img width="1206" height="2622" alt="image" src="https://github.com/user-attachments/assets/d8777538-2895-4735-a60e-be262494c03a" /> | <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/c0637249-a73b-433a-9507-e03c933eca8c" /> | <img width="1206" height="2622" alt="image" src="https://github.com/user-attachments/assets/d85ac2cb-bc8f-4e50-8a00-2f65b90c879d" />
 |

### Error screens

| Service error | Unknown error | No internet connection error | Data processing error |
|---|---|---|---|
| <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/11fd582f-9ff2-4ee6-b5d8-4646015e7b88" /> | <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/58758514-e9e2-4c0b-a533-4323713edbc3" />| <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/54d4e5e7-d644-496c-9827-56cd94a1b8ce" /> | <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/b85ccfe3-c1f2-4410-8b55-2904759cc327" /> |

### Extra cases

| Icon screen | Horizontal home screen
|---|---|
| <img width="735" height="1600" alt="image" src="https://github.com/user-attachments/assets/6db8e44f-4f8a-4d70-815e-e3014fe82529" /> | <img width="1600" height="735" alt="image" src="https://github.com/user-attachments/assets/ac2eb94d-14b7-4759-968d-d8ea984d0ae6" /> |

### Coverage testing & Paginated endpoints

| Coverage | Paginated |
|---|---|
| <img width="1033" height="461" alt="image" src="https://github.com/user-attachments/assets/3d2a3a6c-13a3-448f-a99b-03db6a0eba67" /> | <img width="981" height="495" alt="image" src="https://github.com/user-attachments/assets/5a4ea704-01a1-4205-9687-0bea0497da2d" /> |

---

## Architecture

The app follows **Clean Architecture** with three clearly separated layers. The dependency rule is strict: Presentation depends on Domain, Data depends on Domain, and Domain depends on nothing.

```
┌──────────────────────────────────────────────────┐
│                  Presentation                    │
│                                                  │
│  ArticleListView  ──▶  ArticleListViewModel      │
│  ArticleDetailView ──▶ ArticleDetailViewModel    │
│  ErrorView · LoadingView · SplashView            │
└─────────────────────┬────────────────────────────┘
                      │ uses protocols from
                      ▼
┌──────────────────────────────────────────────────┐
│                    Domain                        │
│                                                  │
│  Article · ArticlePageResult · AppError          │
│  ArticleRepository (protocol)                    │
│  FetchArticlesUseCase                            │
└─────────────────────┬────────────────────────────┘
                      │ implemented by
                      ▼
┌──────────────────────────────────────────────────┐
│                     Data                         │
│                                                  │
│  ArticleRepositoryImpl · ArticleMapper           │
│  URLSessionAPIClient · APIEndpoint               │
│  ArticleDTO · ArticleListDTO                     │
└──────────────────────────────────────────────────┘
```

### Folder structure

```
SpaceFlightNews/
├── App/
│   ├── SpaceFlightNewsApp.swift   # @main entry point + splash logic
│   ├── AppDependencies.swift      # Manual DI composition root
│   ├── AppLogger.swift            # Centralised os.Logger wrapper
│   └── Strings.swift              # translate() — localisation helper
├── Domain/
│   ├── Models/                    # Article, ArticlePageResult, AppError
│   ├── Repositories/              # ArticleRepository protocol
│   └── UseCases/                  # FetchArticlesUseCase
├── Data/
│   ├── DTOs/                      # ArticleDTO, ArticleListDTO
│   ├── Mappers/                   # ArticleMapper (DTO → Domain)
│   ├── Network/                   # URLSessionAPIClient, APIEndpoint
│   └── Repositories/              # ArticleRepositoryImpl
├── Presentation/
│   ├── ArticleList/               # List view + ViewModel
│   ├── ArticleDetail/             # Detail view + ViewModel
│   └── Common/                    # ViewState, ErrorView, LoadingView, SplashView
└── Localizable.strings            # All UI copy — one place, easy to localise
```

---

## Features

- **Paginated list** — cursor-based pagination using the API's `next` URL field, which avoids duplicate articles if new ones are published between page requests
- **Pull-to-refresh** — always resets to page 1 and re-fetches fresh data
- **Client-side search** — instant title filtering on already-loaded articles, no extra network call
- **Error states** — distinct UI for no internet, server error, and data issues, each with a retry action
- **Empty states** — separate views for "API returned nothing" vs "search matched nothing"
- **Splash screen** — shown exactly once on cold launch; dismissed as soon as the first page loads
- **Localisation-ready** — all UI copy lives in `Localizable.strings`; adding a new language requires only a new `.lproj` folder

---

## Key Technical Decisions

### Zero external dependencies

`async/await` + `URLSession` cover networking. `JSONDecoder` covers parsing. `AsyncImage` covers image loading.

### `@Observable` instead of `ObservableObject`

`@Observable` (iOS 17) eliminates the need for `@Published` and avoids Swift 6 global actor isolation conflicts that arise with `ObservableObject` when the ViewModel is `@MainActor`.

### Cursor-based pagination

The API returns a `next` URL with each response. Using that URL as the cursor — instead of calculating an offset manually — guarantees consistent pages even when new articles are published between requests.

### Client-side search

The API supports server-side search, but filtering locally avoids a network round-trip for every keystroke and keeps the UX instant. The trade-off is that search only covers the articles already loaded — acceptable for a news-feed use case.

### Manual dependency injection

Dependencies are composed in `AppDependencies` at the `@main` entry point. No DI framework is needed at this scale; manual wiring is transparent, zero-magic, and easy to follow during a code review.

### `AppError` — four cases, no status codes in the UI

The error enum has exactly four cases: `networkUnavailable`, `serverError`, `dataCorrupted`, and `unknown`. Status codes are preserved internally for logging but never surfaced to the user.

### `ViewState<T>` generic enum

```swift
enum ViewState<T: Sendable>: Sendable {
    case idle, loading, success(T), empty, error(AppError)
}
```

`empty` is a first-class state (not a special case of `success([])`), which allows the UI to distinguish between "nothing loaded yet" and "API confirmed there's nothing".

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 16.0 or later |
| iOS Deployment Target | 17.0 |
| Swift | 5.9 |
| External dependencies | None |

---

## Running the project

1. Clone the repository
2. Open `SpaceFlightNews/SpaceFlightNews.xcodeproj` in Xcode
3. Select a simulator or device running iOS 17+
4. Press **⌘ + R**

No package resolution or additional setup required.

---

## Running the tests

### Unit + performance tests

Press **⌘ + U** or run from the command line:

```bash
xcodebuild test \
  -project SpaceFlightNews/SpaceFlightNews.xcodeproj \
  -scheme SpaceFlightNews \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### UI tests

UI tests require a simulator with network access. Select the `SpaceFlightNewsUITests` scheme and press **⌘ + U**.

---

## Test coverage

<!-- Add coverage screenshot from Xcode here -->

The test suite covers three layers:

| Suite | Tests | What's covered |
|---|---|---|
| `ArticleMapperTests` | 10 | Field mapping, URL validation, ISO 8601 date parsing (with and without fractional seconds), fallback to `.distantPast`, list mapping, skipping invalid entries, **performance** (100 DTOs) |
| `FetchArticlesUseCaseTests` | 7 | Routing (nil cursor → `fetchArticles`, cursor → `fetchNextPage`), parameter forwarding (search, limit), `nextPageURL` propagation, `AppError` propagation |
| `ArticleListViewModelTests` | 20 | All `ViewState` transitions, pagination (append), refresh (replace), client-side search (filter, case-insensitive, whitespace trim, clear), all guard conditions in `loadNextPageIfNeeded`, non-`AppError` mapped to `.unknown` |

The UI test suite (`ArticleListUITests`) validates article load completion via the search bar's appearance and verifies that text typed into the search field is reflected correctly.

---
## Accessibility                                                                                                                                                          

The app supports **VoiceOver** out of the box. Article rows collapse their child elements (image, title, source, date) into a single accessibility element with a descriptive label, so users navigate the list with one swipe per article instead of four. The "Read full article" button in the detail view includes an accessibility hint that announces the action before the user activates it.

---
## A note on how this was built

This challenge was developed using **Claude Code** (Anthropic's CLI, Pro plan) as an active collaborator throughout the process.

That was a deliberate choice, not a shortcut.

AI-assisted development is not about generating code and shipping it blindly — it's a new way of working that requires the same engineering judgment as always: knowing what to ask, understanding the output, pushing back when something is wrong, and owning every decision. Every architectural choice in this project (clean architecture, zero external dependencies, cursor-based pagination, `@Observable`, the `ViewState<T>` design) was reasoned through and validated, not accepted at face value.

I wanted to show how I work *with* AI, because I genuinely believe that's the direction the industry is heading. The developers who will stand out in the next few years won't be the ones who refuse to use these tools — they'll be the ones who know how to use them well. This challenge was my way of demonstrating exactly that.
