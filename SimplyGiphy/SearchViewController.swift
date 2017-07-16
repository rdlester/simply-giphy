import Moya
import Moya_Gloss
import ReactiveCocoa
import ReactiveSwift
import UIKit

// ViewController managing the Search Screen.
// View is provided by RootView; state by SearchState.
// ViewController is responsible for creating Actions and binding them to the views.
class SearchViewController: UIViewController {

    let provider = ReactiveSwiftMoyaProvider<GiphyService>()

    let state: SearchState = SearchState()

    var root: RootView?

    override func loadView() {
        root = RootView(state: state)

        let searchAction = SearchAction.buildInitialSearch(state: state, provider: provider)
        root?.searchButton.reactive.pressed = CocoaAction(searchAction)
        root?.returnTypedAction = { searchAction.apply(()).start() }
        let pageAction = SearchAction.buildNextPage(state: state, provider: provider)
        root?.gifCollection.infiniteScrollAction = { pageAction.apply(()).start() }

        state.input <~ root!.searchInput.reactive.continuousTextValues.map { $0 ?? "" }

        view = root
    }
}
