import ReactiveSwift

// An enum representing the current results of searching.
enum SearchResultState {
    case none // No requests made yet.
    case error // Most recent request to Giphy failed.
    case searching(query: String) // Making a request.
    case results(query: String, results: [Gif], page: Pagination) // Response received.

    // Whether more pages of results are available.
    func canPage() -> Bool {
        switch self {
        case let .results(_, _, page):
            guard let offset = page.offset,
                let count = page.count,
                let totalCount = page.totalCount else {
                return false
            }
            return offset + count < totalCount
        default:
            return false
        }
    }

    // Appends a new batch of results to the current result.
    func appendResults(newResults: [Gif], newPage: Pagination) -> SearchResultState {
        switch self {
        case let .results(query, results, _):
            return .results(query: query, results: results + newResults, page: newPage)
        default:
            return self
        }
    }

    func isError() -> Bool {
        guard case .error = self else { return false }
        return true
    }

    func isSearching() -> Bool {
        guard case .searching = self else { return false }
        return true
    }

    func isResult() -> Bool {
        guard case .results = self else { return false }
        return true
    }
}

// State for the Search Screen.
final class SearchState {
    // The results obtained for the current search.
    var searchResults: MutableProperty<SearchResultState> = MutableProperty(.none)

    // The current contents of the search text input.
    var input: MutableProperty<String> = MutableProperty("")
}
