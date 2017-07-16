import Moya
import Nimble
import Quick
@testable import SimplyGiphy

class SearchActionTest: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {
        var state: SimplyGiphy.SearchState!
        var provider: ReactiveSwiftMoyaProvider<GiphyService>!
        beforeEach {
            state = SearchState()
            provider = ReactiveSwiftMoyaProvider<GiphyService>(stubClosure: MoyaProvider.immediatelyStub)
        }

        describe("Initial SearchAction") {
            it("successfully performs a new search using the current input") {
                let search = GiphyServiceTestHelpers.goodQuery
                state.input.value = search
                var isSearching = false
                var isResults = false
                state.searchResults.signal.observeValues { result in
                    if result.isSearching() {
                        isSearching = true
                    } else if result.isResult() {
                        isResults = true
                    }
                }
                SearchAction.buildInitialSearch(state: state, provider: provider).apply(()).start()
                expect(isSearching).toEventually(beTrue())
                expect(isResults).toEventually(beTrue())
            }
        }

        describe("Paging SearchAction") {
            it("successfully fetches the next page") {
                let search = GiphyServiceTestHelpers.goodQuery
                state.input.value = search
                let action = SearchAction.buildInitialSearch(state: state, provider: provider)
                let pageAction = SearchAction.buildNextPage(state: state, provider: provider)
                action.values.observeValues { [pageAction] _ in
                    pageAction.apply(()).start()
                }
                action.apply(()).start()

                expect({
                    guard case let .results(_, results, _) = state.searchResults.value else {
                        return .failed(reason: "Not a result")
                    }
                    return results.count == GiphyServiceTestHelpers.fullSize ?
                        .succeeded :
                        .failed(reason: "Wrong count")
                }).toEventually(succeed())
            }
        }

        describe("Empty SearchAction") {
            it("returns no results") {
                let search = GiphyServiceTestHelpers.badQuery
                state.input.value = search
                SearchAction.buildInitialSearch(state: state, provider: provider).apply(()).start()
                expect({
                    guard case let .results(_, results, _) = state.searchResults.value else {
                        return .failed(reason: "Not a result")
                    }
                    return results.count == 0 ? .succeeded : .failed(reason: "Wrong count")
                }).toEventually(succeed())
            }
        }

        describe("Failed SearchAction") {
            it("reports an error") {
                provider = ReactiveSwiftMoyaProvider<GiphyService>(
                    endpointClosure: TestHelpers.failureEndpointClosure,
                    stubClosure: MoyaProvider.immediatelyStub)
                let search = GiphyServiceTestHelpers.goodQuery

                // Pretend another search has occurred.
                state.searchResults.value = .results(query: "", results: [], page: Pagination(json: [:])!)

                state.input.value = search
                SearchAction.buildInitialSearch(state: state, provider: provider).apply(()).start()
                expect({
                    guard case .error = state.searchResults.value else {
                        return .failed(reason: "Not an error")
                    }
                    return .succeeded
                }).toEventually(succeed())
            }
        }
    }
}
