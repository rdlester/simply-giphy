import MaterialComponents.MaterialTextFields
import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit

// The root view of the Search Screen.
// Displays a search input + button and a results screen.
// Handles construction, layout and state binding of main app components.
class RootView: UIView, UITextFieldDelegate {

    static let kInputXInset: CGFloat = 15
    static let kInputYInset: CGFloat = 5
    static let kButtonYOffset: CGFloat = 5
    static let kCollectionYOffset: CGFloat = 5

    let searchInput: MDCTextField
    let searchInputController: MDCTextInputController
    let searchButton: MDCRaisedButton

    let activityIndicator: MDCActivityIndicator
    let errorMessage: UILabel
    let noResultsMessage: UILabel
    let gifCollection: GifCollectionView

    var activityIndicatorAnimationTarget: BindingTarget<Bool> {
        return reactive.makeBindingTarget({ view, animate in
            if animate {
                view.activityIndicator.startAnimating()
            } else {
                view.activityIndicator.stopAnimating()
            }
        })
    }

    var hideKeyboardTarget: BindingTarget<()> {
        return reactive.makeBindingTarget { view, _ in
            view.searchInput.resignFirstResponder()
        }
    }

    var returnTypedAction: () -> Void = {}

    // swiftlint:disable:next function_body_length
    init(state: SearchState) {
        searchInput = MDCTextField()
        searchInput.placeholder = NSLocalizedString(
            "SearchInputPlaceholder", value: "Gifs!", comment: "Text in search input field when field is empty.")
        searchInput.accessibilityLabel = NSLocalizedString(
            "SearchInputA11yLabel", value: "Gif search input", comment: "A11y label for the search input.")
        searchInput.sizeToFit()

        searchInputController = MDCTextInputControllerDefault(textInput: searchInput)

        searchButton = MDCRaisedButton()
        searchButton.setTitle(
            NSLocalizedString("SearchButton", value: "Search", comment: "Text in the search button"),
            for: .normal)
        searchButton.sizeToFit()

        errorMessage = UILabel()
        errorMessage.text = NSLocalizedString(
            "Error",
            value: "Network failure!",
            comment: "Error message to show the user when a search request fails")
        errorMessage.textColor = UIColor.black
        errorMessage.sizeToFit()

        noResultsMessage = UILabel()
        noResultsMessage.text = NSLocalizedString(
            "NoResults",
            value: "No results!",
            comment: "Message to display if no results are found for the provided search")
        noResultsMessage.textColor = UIColor.black
        noResultsMessage.sizeToFit()

        activityIndicator = MDCActivityIndicator()
        activityIndicator.cycleColors = []
        activityIndicator.isHidden = true
        activityIndicator.sizeToFit()

        gifCollection = GifCollectionView(state: state.searchResults)

        super.init(frame: CGRect.zero)

        searchInput.delegate = self

        backgroundColor = UIColor.white

        addSubview(searchInput)
        addSubview(searchButton)
        addSubview(errorMessage)
        addSubview(noResultsMessage)
        addSubview(activityIndicator)
        addSubview(gifCollection)
        setUpStateDeps(state)
    }

    private func setUpStateDeps(_ state: SearchState) {
        // Set up external state dependencies.
        hideKeyboardTarget <~ state.searchResults.signal.map { _ in () }

        searchButton.reactive.isEnabled <~ state.input.map { (text: String?) -> Bool in
            if let disabled = text?.isEmpty {
                return !disabled
            }
            return false
        }

        noResultsMessage.reactive.isHidden <~ state.searchResults.map {
            guard case let .results(_, results, _) = $0 else {
                return true
            }
            return !results.isEmpty
        }

        errorMessage.reactive.isHidden <~ state.searchResults.map { !$0.isError() }

        activityIndicator.reactive.isHidden <~ state.searchResults.map { !$0.isSearching() }
        activityIndicatorAnimationTarget <~ state.searchResults.map { $0.isSearching() }

        gifCollection.reactive.isHidden <~ state.searchResults.map {
            guard case let .results(_, results, _) = $0 else {
                return true
            }
            return results.isEmpty
        }
    }

    required init?(coder _: NSCoder) {
        // Not supported.
        return nil
    }

    override func layoutSubviews() {
        searchInput.frame = CGRect(
            x: RootView.kInputXInset,
            y: RootView.kInputYInset,
            width: frame.width - 2 * RootView.kInputXInset,
            height: searchInput.frame.height)
        searchButton.frame = CGRect(
            x: (frame.width - searchButton.frame.width) * 0.5,
            y: searchInput.frame.height + RootView.kButtonYOffset,
            width: searchButton.frame.width,
            height: searchButton.frame.height)

        let collectionY = searchButton.frame.maxY + RootView.kCollectionYOffset
        let remainingHeight = frame.height - collectionY

        noResultsMessage.frame = CGRect(
            x: (frame.width - noResultsMessage.frame.width) * 0.5,
            y: collectionY,
            width: noResultsMessage.frame.width,
            height: noResultsMessage.frame.height)
        errorMessage.frame = CGRect(
            x: (frame.width - errorMessage.frame.width) * 0.5,
            y: collectionY,
            width: errorMessage.frame.width,
            height: errorMessage.frame.height)
        activityIndicator.frame = CGRect(
            x: (frame.width - activityIndicator.frame.width) * 0.5,
            y: collectionY,
            width: activityIndicator.frame.width,
            height: 2 * activityIndicator.radius)
        gifCollection.frame = CGRect(x: 0, y: collectionY, width: frame.width, height: remainingHeight)
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        returnTypedAction()
        return true
    }
}
