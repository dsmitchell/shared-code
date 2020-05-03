//
//  VideoViewController.swift
//  Shared
//
//  Copyright © 2020 The App Studio LLC. All rights reserved.
//

import Foundation

/// ViewController for iOS, macOS, and tvOS that plays a video (leverages Storyboards for platform-specific construction and layout)
public final class VideoViewController: ViewController {

	/// Platform-agnostic Button
	@IBOutlet var playButton: Button!

	@IBAction func playButtonTapped(_ sender: Button) {
		guard let videoPlayerView = view as? VideoPlayerView else { return }
		videoPlayerView.play()
		sender.isEnabled = !videoPlayerView.isPlaying
	}

	override public func viewDidLoad() {
		super.viewDidLoad()
		guard let videoPlayerView = view as? VideoPlayerView else { return }
		videoPlayerView.videoUrl = Bundle.main.url(forResource: "intro", withExtension: "mov")
	}
}

/// `VideoPlayerViewDelegate` support for `VideoViewController`. Delegate assigned in the Storyboards
extension VideoViewController: VideoPlayerViewDelegate {

	public func videoPlayerViewReady(_ videoPlayerView: VideoPlayerView) {
		playButton.isEnabled = true
	}

	public func videoPlayerViewDidFinishPlaying(_ videoPlayerView: VideoPlayerView) {
		videoPlayerView.reset()
	}
}
