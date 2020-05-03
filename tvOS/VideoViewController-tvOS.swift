//
//  VideoViewController-tvOS.swift
//  Shared-tvOS
//
//  Copyright © 2020 The App Studio LLC. All rights reserved.
//

import UIKit

/// tvOS-specific customizations of VideoViewController
extension VideoViewController {

	override public var preferredFocusEnvironments: [UIFocusEnvironment] {
		return [playButton]
	}
}
