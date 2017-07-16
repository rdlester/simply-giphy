import Nimble
import Quick
@testable import SimplyGiphy

class RootViewTest: QuickSpec {

    // swiftlint:disable:next function_body_length
    override func spec() {
        var state: SearchState!
        var root: RootView!
        beforeEach {
            state = SearchState()
            root = RootView(state: state)
        }

        describe("RootView") {
            it("Initializes visibility correctly") {
                expect(root.activityIndicator.isHidden).to(beTrue())
                expect(root.errorMessage.isHidden).to(beTrue())
                expect(root.noResultsMessage.isHidden).to(beTrue())
                expect(root.gifCollection.isHidden).to(beTrue())
            }

            it("updates visibility during a search") {
                state.searchResults.value = .searching(query: "")
                expect(root.activityIndicator.isHidden).to(beFalse()) // Shown.
                expect(root.errorMessage.isHidden).to(beTrue())
                expect(root.noResultsMessage.isHidden).to(beTrue())
                expect(root.gifCollection.isHidden).to(beTrue())
            }

            it("updates visibility after a successful search") {
                // Initialize with a single empty element.
                state.searchResults.value = .results(query: "",
                                                     results: [Gif(json: [:])!],
                                                     page: Pagination(json: [:])!)
                expect(root.activityIndicator.isHidden).to(beTrue())
                expect(root.errorMessage.isHidden).to(beTrue())
                expect(root.noResultsMessage.isHidden).to(beTrue())
                expect(root.gifCollection.isHidden).to(beFalse()) // Shown.
            }

            it("updates visibility after an empty search") {
                state.searchResults.value = .results(query: "", results: [], page: Pagination(json: [:])!)
                expect(root.activityIndicator.isHidden).to(beTrue())
                expect(root.errorMessage.isHidden).to(beTrue())
                expect(root.noResultsMessage.isHidden).to(beFalse()) // Shown.
                expect(root.gifCollection.isHidden).to(beTrue())
            }

            it("updates visibility after a failed search") {
                state.searchResults.value = .error
                expect(root.activityIndicator.isHidden).to(beTrue())
                expect(root.errorMessage.isHidden).to(beFalse()) // Shown.
                expect(root.noResultsMessage.isHidden).to(beTrue())
                expect(root.gifCollection.isHidden).to(beTrue())
            }
        }
    }
}
