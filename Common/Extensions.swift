//
//  Extensions.swift
//  Shared
//
//  Copyright © 2018 The App Studio LLC. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Shims

// NOTE: ONLY use these shims where you intend to use the same Swift code for multiple platforms

#if os(iOS) || os(tvOS)

import UIKit

public typealias Application = UIApplication
public typealias Button = UIButton
public typealias Label = UILabel
public typealias Size = CGSize
public typealias View = UIView
public typealias ViewController = UIViewController

#elseif os(macOS)

import AppKit

public typealias Application = NSApplication
public typealias Button = NSButton
public typealias Label = NSTextField
public typealias Size = NSSize
public typealias View = NSView
public typealias ViewController = NSViewController

#endif

// MARK: - Other sample extensions

public extension CGSize {

	/// Returns a `CGSize` that represents no intrinsic size for autolayout purposes
	static var noIntrinsicSize: CGSize {
		#if os(macOS)
		return CGSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
		#else
		return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
		#endif
	}
}

public extension DispatchQueue {

	/// Ensures a block is executed within the main thread, synchronously
	class func runInMain(_ block: () -> Void) {
		if Thread.isMainThread {
			block()
		} else {
			main.sync(execute: block)
		}
	}
}
