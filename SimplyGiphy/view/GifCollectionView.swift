import MaterialComponents
import Moya
import ReactiveSwift
import UIKit

// A CollectionView displaying Gifs obtained for the current search.
class GifCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let kCollectionSpacing: CGFloat = 1
    static let kInfiniteIndicatorInset: CGFloat = 5

    let state: MutableProperty<SearchResultState>

    // Target that updates scroll without animation.
    var contentOffsetTarget: BindingTarget<CGPoint> {
        return reactive.makeBindingTarget { view, point in
            view.setContentOffset(point, animated: false)
        }
    }

    // Target that updates the footer size.
    var footerTarget: BindingTarget<CGSize> {
        return reactive.makeBindingTarget { view, size in
            view.layout.footerReferenceSize = size
        }
    }

    let layout: UICollectionViewFlowLayout

    let infiniteScrollIndicator: MDCActivityIndicator

    // An action executed when the user scrolls to the end of the current results if more results are available.
    // Expected to be bound by the owning ViewController.
    var infiniteScrollAction: () -> Void = {}

    // MARK: class methods

    class func imageForGif(gif: Gif) -> ImageFormat? {
        return gif.images?.fixedWidth
    }

    class func idForFooter() -> String {
        return "footer"
    }

    // MARK: init

    init(state: MutableProperty<SearchResultState>) {
        self.state = state

        infiniteScrollIndicator = MDCActivityIndicator()
        infiniteScrollIndicator.cycleColors = []
        infiniteScrollIndicator.sizeToFit()

        layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = GifCollectionView.kCollectionSpacing
        super.init(frame: CGRect.zero, collectionViewLayout: layout)

        // Register cell types.
        register(GifCollectionCell.self, forCellWithReuseIdentifier: GifCollectionCell.id)
        register(UICollectionReusableView.self,
                 forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                 withReuseIdentifier: GifCollectionView.idForFooter())

        // Register UICollectionView info providers.
        delegate = self
        dataSource = self

        // Style.
        backgroundColor = UIColor.white

        setUpStateDeps(state)
    }

    private func setUpStateDeps(_ state: MutableProperty<SearchResultState>) {
        // Post notifications on failures.
        state.signal.observeValues { results in
            if case .error = results {
                let annoucement = NSLocalizedString(
                    "SearchFailedNotification",
                    value: "Network failed",
                    comment: "Notifies the user that the network request for the current search has failed")
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, annoucement)
                return
            }

            guard case let .results(_, gifs, _) = results else { return }

            let newResultsAnnoucement = NSLocalizedString(
                "SearchCompletedNotification",
                value: "New results found",
                comment: "Notifies the user that new results have been obtained for the current search")
            let noResultsAnnouncement = NSLocalizedString(
                "SearchEmptyNotification",
                value: "No results found",
                comment: "Notifies the user that no results have been obtained for the current search")
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                            gifs.isEmpty ? noResultsAnnouncement : newResultsAnnoucement)
        }

        contentOffsetTarget <~ state.signal.filter { result in result.isSearching() }.map { _ in CGPoint.zero }

        reactive.reloadData <~ state.signal.filter { result in result.isResult() }.map { _ in () }

        let radius = infiniteScrollIndicator.radius
        footerTarget <~ state.signal.map { results in
            return CGSize(width: 0,
                          height: results.canPage() ? 2 * (radius + GifCollectionView.kInfiniteIndicatorInset) : 0)
        }
    }

    required init?(coder _: NSCoder) {
        // InterfaceBuilder not supported.
        return nil
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        guard case let .results(_, gifs, _) = state.value else {
            return 0
        }
        return gifs.count
    }

    func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = dequeueReusableCell(withReuseIdentifier: GifCollectionCell.id, for: indexPath) as! GifCollectionCell
        guard case let .results(_, gifs, _) = state.value else {
            return cell
        }
        cell.image = GifCollectionView.imageForGif(gif: gifs[indexPath.item])
        return cell
    }

    func collectionView(_: UICollectionView,
                        viewForSupplementaryElementOfKind _: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter,
                                                    withReuseIdentifier: GifCollectionView.idForFooter(),
                                                    for: indexPath)
        view.addSubview(infiniteScrollIndicator)
        infiniteScrollIndicator.frame.origin.x = (frame.width - infiniteScrollIndicator.frame.width) * 0.5
        infiniteScrollIndicator.startAnimating()

        // Since the footer is only requested when necessary for display, we can treat this as a signal that the user
        // has scrolled to the bottom of the list.
        // Perform the associated action.
        infiniteScrollAction()

        return view
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard case let .results(_, gifs, _) = state.value,
            let image = GifCollectionView.imageForGif(gif: gifs[indexPath.item]),
            let width = image.width.map({ CGFloat($0) }),
            let height = image.height.map({ CGFloat($0) }) else {
            return CGSize.zero
        }
        return CGSize(width: width, height: height)
    }
}
