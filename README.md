SimplyGiphy is a simple single-view iOS app that can search for and display gifs from Giphy.

## Build
To build: you'll need to add an api_keys.plist to the SimplyGiphy directory, containing the key "giphy" whose value is an API key for the Giphy API. This is a simple way to keep the API key off Github, though additional obfuscation is required to fully protect it.

The app can be built from `SimplyGiphy.xcworkspace`. Dependencies are included, but can be updated using [Cocoapods](https://cocoapods.org/).

## Overview
At the root of the app's architecture is the `GiphyService`. This models the Giphy API in Swift using [Moya](https://github.com/Moya/Moya). Moya allows us to define the API in a declarative fashion using Swift enums, allowing us to focus on the structure of Giphy's API instead of juggling NSURLSessions or even Alamofire Managers. It also provides bindings to ReactiveSwift.

Responses are decoded into Swift models via [Gloss](https://github.com/hkellaway/Gloss), which provides a clean syntax for performing JSON decoding. [MoyaGloss](https://github.com/spxrogers/Moya-Gloss) provides helper methods for decoding `Moya.Response`s. These models are contained in `GiphyModel.swift`, and map to the objects described on the Giphy API docs. (The one exception is ImageFormat, which attempts to standardize the data associated with different formats defined in the Images object.)

Application state is defined in `SearchState`. This contains two values: `input`, which models user input into a text field; and `results`, which models request state. `results` is of type `SearchResultState`, an enum with different cases modeling possible request states: `.none`, `.searching(String)`, `.error` and `.results(String, [Gif], Pagination)`. All paramters in `SearchState` are public and wrapped in `MutableProperty` from [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), which allows us to monitor state updates using ReactiveSwift `Signal`s / `BindingTarget`s and directly bind views to the model.

`SearchAction` provides factory methods that wrap the `SignalProvider`s managing requests in Moya's ReactiveSwift integration in ReactiveSwift `Action`s. There are two actions: one for starting a search with a new query, and another for obtaining subsequent pages of results. Both are bound to `SearchState`; the first creates an entirely new `.results` if successful, the other appends to an existing `.results`. Both actions also automatically decode their responses to the corresponding model object (`SearchResponse`).

The UI is managed programmatically. `RootView` is at the root, and contains an input, a search button, a `GifCollectionView`, an activity indicator, and labels for handling error or zero states. `GifCollectionView` manages a collection of `GifCollectionCell`s, which use AVKit to display gifs in mp4 format. `SearchState` is provided to both `RootView` and `GifCollectionView`, which bind as required. `RootView` binds visibility and enabled states of its various components to `SearchState`; `GifCollectionView` maps from `.result` to `GifCollectionCell`s on update. Binding is done using extensions on UIKit provided by [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa). The input, button and activity indicator use existing components from [Google Material Components iOS](https://github.com/material-components/material-components-ios). Strings are localized. The UI is accessible.

The UI does not directly bind to actions but exposes binding points. The press event for the search button in `RootView` is exposed as a `CocoaAction` via ReactiveCocoa. `GifCollectionView` exposes a closure parameter that executes when the user scrolls to the end of the current results, if more results are available.

`SearchViewController` manages instantiating state, views and actions and binding them together. The `AppDelegate` instantiates a `SearchViewController` and displays it.

Tests are provided for `SearchAction`, `RootView` and `GifCollectionView` using [Quick / Nimble](https://github.com/Quick/Nimble).

Code style is checked and formatted using [swiftlint](https://github.com/realm/SwiftLint) and [swiftformat](https://github.com/nicklockwood/SwiftFormat). A build rule has been added to the xcodeproj to automatically check style after building the app.

## Why?

This architecture ditches a lot of the traditional delegation-based MVC of iOS in favor of a more functional approach somewhat inspired by frameworks like Om and Redux. There is still a ViewController that owns a view and maintains application state, but our custom State objects encapsulate that actual state, Views directly handle binding to state (and more importantly, only updates on state change), and our Actions handle state updates. The ViewController is only responsible for assembling the pieces.

At a basic level, this is simple dependency injection, separating concerns in order to enable comprehensibility, extensibility and testability.

ReactiveCocoa provides us with a functional version of view-model binding, allowing us to quite literally define mappings between state and views. Without a virtual view representation like that provided by React, we can't implement a pure functional approach that regenerates a virtual view hierarchy on all state updates, but we can express the subset of parameters with dynamic behavior as pure functions over the state. Changes that don't map directly to parameters or can't be represented naturally as such, like posting accessibility notifications, are handled with observers. This is both easy to understand and easy to test.

## Known issues

The most prominent issue in the app lies in the display of gifs. Using AVKit to download and display the gifs in mp4 format is simple and reliable, but makes scrolling very jerky. Alternative methods for display should be investigated, from managing the download and caching of videos ourselves to using different methods for rendering. The app could also use some visual polish (and also app icons and a launch screen).

Architecturally, use of optionals in `GiphyModel` should be reduced; they were used initially to simplify use of Gloss, which doesn't provide great syntax for non-optional parameters. Switching to Argo for JSON parsing (instead of Gloss) would simplify this.

Many of the custom BindingTargets could be moved to extensions over the corresponding base class, both to maximize reusability and to further separate from the bindings.

Accessibility identifiers should be added to enable UI testing. Unit testing could be more fine-grained, but the current tests provide fairly complete coverage. In particular, tests for the models (JSON mapping in `GiphyModel` and helper methods on `SearchResultState`) could be written, but much of the former and all of the latter are covered in existing tests.
