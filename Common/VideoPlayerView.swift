//
//  VideoPlayerView.swift
//  Shared
//
//  Copyright © 2018 The App Studio LLC. All rights reserved.
//

import AVFoundation

/// Notifies delegates of important events regarding VideoPlayerView
@objc public protocol VideoPlayerViewDelegate: NSObjectProtocol {

	@objc optional func videoPlayerView(_ videoPlayerView: VideoPlayerView, encountered error: Error)
	@objc optional func videoPlayerViewDidFinishPlaying(_ videoPlayerView: VideoPlayerView)
	@objc optional func videoPlayerViewReady(_ videoPlayerView: VideoPlayerView)
}

/// Platform-independent View for playing videos via AVPlayerLayer
public final class VideoPlayerView: View {
	
	public typealias VideoPlayerViewLoadCompletion = (_ success: Bool, _ error: Error?) -> Void
	
	@IBOutlet public weak var delegate: VideoPlayerViewDelegate?
	
	public private(set) var isPlaying = false
	
	public private(set) var videoSize = CGSize.zero
	
	public var videoUrl: URL? {
		get { return videoUrlPrivate }
		set { setVideoUrl(newValue, with: nil) }
	}
	
	deinit {
		presentationSizeObserver = nil
		statusObserver = nil
	}
	
	@objc public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		#if os(iOS) || os(tvOS)
		playerLayer.player = self.player
		#elseif os(macOS)
		self.layer = AVPlayerLayer(player: player)
		self.wantsLayer = true
		self.layerContentsRedrawPolicy = .onSetNeedsDisplay
		#endif
		playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
	}
	
	// MARK: - Public methods
	
	public func play() {
		guard isPlaying == false else { return }
		if let currentItem = player.currentItem, currentItem.status == .readyToPlay {
			player.play()
		}
		isPlaying = true
	}
	
	public func pause() {
		player.pause()
		isPlaying = false
	}
	
	public func reset() {
		pause()
		player.seek(to: CMTime.zero) { finished in
			self.notifyReady()
		}
	}
	
	public func setVideoUrl(_ videoUrl: URL?, options: [String : Any]? = nil, with completion: VideoPlayerViewLoadCompletion?) {
		guard videoUrlPrivate != videoUrl else {
			guard let completion = completion else { return }
			completion(asset != nil && videoUrl != nil, nil)
			return
		}
		videoUrlPrivate = videoUrl
		guard let videoUrl = videoUrl else {
			self.asset = nil
			guard let completion = completion else { return }
			completion(true, nil)
			return
		}
		let pendingAsset = AVURLAsset(url: videoUrl, options: options)
		pendingAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
			DispatchQueue.runInMain {
				var error: NSError? = nil
				let loaded = pendingAsset.statusOfValue(forKey: "tracks", error: &error) == .loaded
				if loaded {
					self.asset = pendingAsset
				} else {
					self.asset = nil
				}
				if let completion = completion {
					completion(loaded, error)
				}
				if let error = error {
					self.notifyError(error)
				}
			}
		}
	}
	
	// MARK: - ViewController overrides
	
	override public var intrinsicContentSize: Size {
		guard videoSize != .zero else { return .noIntrinsicSize }
		return videoSize
	}
	
	#if os(macOS)
	
	override public var wantsUpdateLayer: Bool {
		return true
	}
	
	#elseif os(iOS) || os(tvOS)
	
	override public class var layerClass: AnyClass {
		return AVPlayerLayer.self
	}

	#endif
	
	override public func removeFromSuperview() {
		self.asset = nil
		super.removeFromSuperview()
	}
	
	// MARK: - Private properties and methods
	
	var asset: AVAsset? {
		didSet { self.playerItem = asset == nil ? nil : AVPlayerItem(asset: asset!) }
	}
	let player = AVPlayer()
	var playerItem: AVPlayerItem? {
		willSet {
			pause()
			presentationSizeObserver?.invalidate()
			statusObserver?.invalidate()
			guard let playerItem = playerItem else { return }
			NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
			NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
		}
		didSet {
			if let playerItem = playerItem {
				presentationSizeObserver = playerItem.observe(\AVPlayerItem.presentationSize) { item, change in
					DispatchQueue.runInMain {
						self.videoSize = playerItem.presentationSize
						self.invalidateIntrinsicContentSize()
					}
				}
				statusObserver = playerItem.observe(\AVPlayerItem.status) { item, change in
					DispatchQueue.runInMain {
						switch (playerItem.status, change.oldValue) {
						case (.readyToPlay, .readyToPlay?):
							if self.isPlaying {
								self.player.play()
							}
						case (.readyToPlay, _):
							self.notifyReady()
						case (.failed, _):
							guard let error = playerItem.error else {
								return
							}
							self.notifyError(error)
						default:
							break
						}
					}
				}
				NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidEncounterError(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
				NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
			} else {
				presentationSizeObserver = nil
				statusObserver = nil
			}
			player.replaceCurrentItem(with: playerItem)
			#if os(macOS)
			needsDisplay = true
			#elseif os(iOS) || os(tvOS)
			setNeedsDisplay()
			#endif
		}
	}
	private var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer
	}
	private var presentationSizeObserver: NSKeyValueObservation?
	private var statusObserver: NSKeyValueObservation?
	private var videoUrlPrivate: URL?

	fileprivate func notifyError(_ error: Error) {
		guard let videoPlayerViewEncounteredError = delegate?.videoPlayerView else { return }
		videoPlayerViewEncounteredError(self, error)
	}
	
	fileprivate func notifyFinishedPlaying() {
		guard let videoPlayerViewDidFinishPlaying = delegate?.videoPlayerViewDidFinishPlaying else { return }
		videoPlayerViewDidFinishPlaying(self)
	}
	
	fileprivate func notifyReady() {
		guard let videoPlayerViewReady = delegate?.videoPlayerViewReady else { return }
		videoPlayerViewReady(self)
	}
}

// MARK: - Notification listeners
extension VideoPlayerView {
	
	@objc func playerItemDidEncounterError(_ notification: Notification) {
		guard let item = notification.object as? AVPlayerItem, item == player.currentItem, let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error else {
			return
		}
		notifyError(error)
	}
	
	@objc func playerItemDidReachEnd(_ notification: Notification) {
		guard let item = notification.object as? AVPlayerItem, item == player.currentItem else {
			return
		}
		isPlaying = false
		notifyFinishedPlaying()
	}
}
