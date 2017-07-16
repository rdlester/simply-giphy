import Moya

// A Moya Service for Giphy.
enum GiphyService {
    case search(api_key: String, q: String, limit: Int?, offset: Int?, rating: String?)

    static func bundledApiKey() -> String? {
        guard let path = Bundle.main.path(forResource: "api_keys", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return plist["giphy"] as? String
    }
}

// MARK: TargetType

extension GiphyService: TargetType {
    var baseURL: URL { return URL(string: "https://api.giphy.com")! }

    var path: String {
        switch self {
        case .search:
            return "/v1/gifs/search"
        }
    }

    var method: Moya.Method {
        switch self {
        case .search:
            return .get
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .search(api_key, q, limit, offset, rating):
            var params: [String: Any] = ["api_key": api_key, "q": q]
            params["limit"] = limit
            params["offset"] = offset
            params["rating"] = rating
            return params
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
        case .search:
            return URLEncoding.default
        }
    }

    var sampleData: Data {
        switch self {
        case let .search(_, q, _, offset, _):
            return GiphyServiceTestHelpers.sampleDataFor(q: q, offset: offset)
        }
    }

    var task: Task {
        switch self {
        case .search:
            return .request
        }
    }
}

// Static properties and methods for help with tests.
struct GiphyServiceTestHelpers {
    // The query for which results are available in test.
    static let goodQuery: String = "aquabats"

    // Anything other than goodQuery will return empty results, but using this will guarantee no collision.
    static let badQuery: String = "foo"

    // The size of the initial results fetched for `goodQuery` in test.
    static let initialSearchSize: Int = 25

    // The full size of results available for `goodQuery` in test.
    static let fullSize: Int = 46

    // Obtains the sample data from the bundle.
    // swiftlint:disable:next identifier_name
    static func sampleDataFor(q: String, offset: Int?) -> Data {
        // swiftlint:disable:next force_cast
        let bundle = Bundle(for: DummyClass.self)
        var fileName: String!
        if q != "aquabats" {
            fileName = "empty_search"
        } else if let offset = offset {
            fileName = offset == 0 ? "sample_search" : "sample_search_next_page"
        } else {
            fileName = "sample_search"
        }
        guard let fileURL = bundle.url(forResource: fileName, withExtension: "json"),
            let data = try? Data(contentsOf: fileURL)
        else {
            return Data()
        }
        return data
    }
}

// Private class needed to correctly resolve Bundle.
private class DummyClass {}
