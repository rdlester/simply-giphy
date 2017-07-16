import Moya
import Moya_Gloss
import ReactiveSwift

// Action for making searches against the Giphy API and updating SearchState accordingly.
struct SearchAction {
    // An action performing an entirely new search.
    // Updates SearchState.query to the new search, resets SearchState.searchResults to the returned Gifs.
    static func buildInitialSearch(state: SearchState, provider: ReactiveSwiftMoyaProvider<GiphyService>)
        -> Action<(), SearchResultState, MoyaError> {
        // Produce the backing ReactiveSwift.Action.
        let action = Action { [weak provider] (_: Void) -> SignalProducer<SearchResultState, MoyaError> in
            let query = state.input.value
            let initialProducer = SignalProducer<SearchResultState, MoyaError>(value: .searching(query: query))
            let request = SearchAction.buildRequest(q: query, offset: 0, provider: provider)
                .map { (response: SearchResponse) -> SearchResultState in
                    guard let gifs = response.data,
                        let page = response.pagination else {
                        return .error
                    }
                    return .results(query: query, results: gifs, page: page)
                }
            return SignalProducer.merge([initialProducer, request])
        }

        // Bind to SearchState.
        state.searchResults <~ action.values

        state.searchResults <~ action.errors.map { _ in .error }

        return action
    }

    // An action obtaining additional results for an already-initialized search.
    // Appends Gifs to SearchState.searchResults.
    static func buildNextPage(state: SearchState, provider: ReactiveSwiftMoyaProvider<GiphyService>)
        -> Action<(), SearchResultState, MoyaError> {
        let action =
            Action(state: state.searchResults,
                   enabledIf: { _ in true }, { [weak provider] (state: SearchResultState, _: Void)
                       -> SignalProducer<SearchResultState, MoyaError> in
                       if !state.canPage() {
                           return SignalProducer(error: MoyaError.underlying(NSError(
                               domain: "sfsfsf.SimplyGiphy",
                               code: 0,
                               userInfo: [NSLocalizedDescriptionKey: "Next page requested for invalid state"])))
                       }
                       guard case let .results(query, _, page) = state,
                           let offset = page.offset,
                           let count = page.count else {
                           return SignalProducer(error: MoyaError.underlying(SearchAction.noStateError()))
                       }
                       return SearchAction.buildRequest(q: query, offset: offset + count, provider: provider)
                           .map { response in
                               guard let newGifs = response.data,
                                   let newPage = response.pagination else {
                                   return .error
                               }
                               return state.appendResults(newResults: newGifs, newPage: newPage)
                           }
            })

        // Merge the new page with the old results.
        state.searchResults <~ action.values
        state.searchResults <~ action.errors.map { _ in .error }

        return action
    }

    // Builds the request Producer from Moya.
    // swiftlint:disable:next identifier_name
    private static func buildRequest(q: String?, offset: Int?, provider: ReactiveSwiftMoyaProvider<GiphyService>?)
        -> SignalProducer<SearchResponse, MoyaError> {
        guard let provider = provider else {
            return SignalProducer(error: MoyaError.underlying(SearchAction.noStateError()))
        }
        return provider.request(.search(
            api_key: GiphyService.bundledApiKey() ?? "",
            q: q ?? "",
            limit: 25,
            offset: offset,
            rating: "g"))
            .flatMap(.latest, transform: decodeSearchRequest)
    }

    // Error thrown if objects used to create Actions are deinit when an Action is called.
    private static func noStateError() -> NSError {
        return NSError(
            domain: "sfsfsf.SimplyGiphy.error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Action called after State deinit"])
    }

    // Transform for SignalProducer.flatMap that decodes a raw response to a SearchResponse using MoyaGloss.
    private static func decodeSearchRequest(response: Moya.Response) -> SignalProducer<SearchResponse, MoyaError> {
        do {
            return SignalProducer(value: try response.mapObject(SearchResponse.self))
        } catch {
            if let error = error as? MoyaError {
                return SignalProducer(error: error)
            } else {
                return SignalProducer(error: MoyaError.underlying(error as NSError))
            }
        }
    }
}
