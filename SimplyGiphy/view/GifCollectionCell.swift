import AVFoundation
import AVKit
import UIKit

// An individual CollectionViewCell displaying a single ImageFormat from a Gif in .mp4 format.
class GifCollectionCell: UICollectionViewCell {

    static let id = "GifCollectionCell" // swiftlint:disable:this identifier_name

    let gifPlayer: AVPlayerViewController

    var playbackObserver: NSObjectProtocol?

    var image: ImageFormat? {
        didSet {
            // Create an AVPlayer using the new image and attach to gifPlayer.
            guard let assetURL = image?.mp4 else {
                return
            }
            let asset = AVAsset(url: assetURL)
            let playerItem = AVPlayerItem(asset: asset)
            if let player = gifPlayer.player {
                player.replaceCurrentItem(with: playerItem)
            } else {
                gifPlayer.player = AVPlayer(playerItem: playerItem)
            }

            // Autoplay.
            gifPlayer.player!.play()

            // Set up an observer to trigger looping.
            if let oldObserver = playbackObserver {
                NotificationCenter.default.removeObserver(oldObserver)
            }
            playbackObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: gifPlayer.player!.currentItem,
                queue: nil,
                using: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.gifPlayer.player!.seek(to: kCMTimeZero)
                        self?.gifPlayer.player!.play()
                    }
            })
        }
    }

    override init(frame: CGRect) {
        gifPlayer = AVPlayerViewController()
        gifPlayer.showsPlaybackControls = false
        gifPlayer.allowsPictureInPicturePlayback = false
        super.init(frame: frame)
        contentView.addSubview(gifPlayer.view)
    }

    required init?(coder _: NSCoder) {
        // Not supported.
        return nil
    }

    deinit {
        if let oldObserver = playbackObserver {
            NotificationCenter.default.removeObserver(oldObserver)
        }
    }

    override func layoutSubviews() {
        guard let width = image?.width.map({ CGFloat($0) }),
            let height = image?.height.map({ CGFloat($0) }) else {
            return
        }
        gifPlayer.view.frame = CGRect(x: (frame.width - width) * 0.5, y: 0, width: width, height: height)
    }
}
