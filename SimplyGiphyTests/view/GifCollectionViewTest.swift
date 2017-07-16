import Moya
import Nimble
import Quick
import ReactiveSwift
@testable import SimplyGiphy

class GifCollectionViewTests: QuickSpec {
    // swiftlint:disable:next function_body_length
    override func spec() {
        var state: SearchState!
        var view: GifCollectionView!
        var provider: ReactiveSwiftMoyaProvider<GiphyService>! // Use provider for access to sample data.
        beforeEach {
            state = SearchState()
            view = GifCollectionView(state: state.searchResults)
            provider = ReactiveSwiftMoyaProvider<GiphyService>(stubClosure: MoyaProvider.immediatelyStub)
        }

        describe("GifCollectionView") {
            it("initializes correctly") {
                expect(view.layout.footerReferenceSize).to(equal(CGSize.zero))
                expect(view.collectionView(view, numberOfItemsInSection: 0)).to(equal(0))
            }

            it("updates properly with results") {
                state.input.value = GiphyServiceTestHelpers.goodQuery
                let action = SearchAction.buildInitialSearch(state: state, provider: provider)
                action.apply(()).start()
                expect(view.layout.footerReferenceSize).toEventuallyNot(equal(CGSize.zero))
                expect(view.collectionView(view, numberOfItemsInSection: 0))
                    .toEventually(equal(GiphyServiceTestHelpers.initialSearchSize))
            }

            it("resets scroll for new searches") {
                state.input.value = GiphyServiceTestHelpers.goodQuery
                let action = SearchAction.buildInitialSearch(state: state, provider: provider)
                action.apply(()).start()
                view.setContentOffset(CGPoint(x: 0, y: 10), animated: false)
                expect(view.contentOffset).toNot(equal(CGPoint.zero))
                // Reapply same search; should still reset offset.
                action.apply(()).start()
                expect(view.contentOffset).to(equal(CGPoint.zero))
            }
        }
    }
}
