import Moya
@testable import SimplyGiphy

struct TestHelpers {

    static func failureEndpointClosure(target: GiphyService) -> Endpoint<GiphyService> {
        return Endpoint<GiphyService>(
            url: urlForTarget(target),
            sampleResponseClosure: { .networkError(TestHelpers.fakeError()) },
            method: target.method,
            parameters: target.parameters)
    }

    static func fakeError() -> NSError {
        return NSError(
            domain: "sfsfsf.SimplyGiphy.error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Fake error"])
    }

    static func urlForTarget(_ target: GiphyService) -> String {
        return target.baseURL.appendingPathComponent(target.path).absoluteString
    }
}
