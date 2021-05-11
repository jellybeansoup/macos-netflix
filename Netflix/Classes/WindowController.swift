import Cocoa

protocol WindowControllerFullscreenDelegate: class {

	func windowDidEnterFullScreen(_ window: NSWindow)

	func windowDidFailToEnterFullScreen(_ window: NSWindow)

	func windowDidExitFullScreen(_ window: NSWindow)

	func windowDidFailToExitFullScreen(_ window: NSWindow)

}

class WindowController: NSWindowController, NSWindowDelegate {

	weak var fullscreenDelegate: WindowControllerFullscreenDelegate?

	override func windowDidLoad() {
		super.windowDidLoad()

		guard let window = window else {
			return
		}

		window.delegate = self
		window.title = ""
		window.styleMask.insert(.fullSizeContentView)
		window.collectionBehavior.insert(.fullScreenPrimary)
		window.titlebarAppearsTransparent = true
		window.isMovableByWindowBackground = true

		window.setContentSize(NSSize(width: 1280, height: 904))
		window.contentMinSize = NSSize(width: 180, height: 102)

		didSetKeepInFront()
		didSetSnapToCorners()
	}

	// MARK: Lock aspect ratio in videos

	func update(aspectRatio: NSSize?) {
		guard let window = window, let screen = window.screen else {
			return
		}

		if let aspectRatio = aspectRatio, !window.styleMask.contains(.fullScreen) {
			guard window.contentAspectRatio != aspectRatio else {
				return
			}

			window.contentAspectRatio = aspectRatio

			// We want to snap to the corner we're closest to pre-resize
			let preferredCorner = window.frame.preferredCorner(for: screen)

			var frame = window.frame
			frame.size.height = aspectRatio.height / aspectRatio.width * frame.size.width

			if snapToCorners {
				frame.origin = frame.originForSnapping(to: preferredCorner, of: screen, with: snapInset)
			}
			else {
				// When not snapping, scale towards the center of the window.
				frame.origin.y += (window.frame.size.height - frame.size.height) / 2
			}

			window.setFrame(frame, display: true, animate: true)
		}
		else {
			window.contentResizeIncrements = NSSize(width: 1, height: 1)
		}
	}

	// MARK: Keep in front

	static private let keepInFrontKey = "com.jellystyle.Netflix.WindowController.KeepInFront"

	private func didSetKeepInFront() {
		guard let window = window else {
			return
		}

		window.level = self.keepInFront ? .modalPanel : .normal
	}

	var keepInFront: Bool {
		get { return (UserDefaults.standard.object(forKey: WindowController.keepInFrontKey) as? NSNumber)?.boolValue ?? true }
		set {
			UserDefaults.standard.set(NSNumber(value: newValue), forKey: WindowController.keepInFrontKey)
			didSetKeepInFront()
		}
	}

	@IBAction func toggleKeepInFront(_ sender: Any?) {
		self.keepInFront = !self.keepInFront
	}

	// MARK: Snap to corners

	static private let snapToCornersKey = "com.jellystyle.Netflix.WindowController.SnapToCorners"

	private let snapInset = NSRect.Corner.Insets(x: 20, y: 20)

	private func didSetSnapToCorners() {
		guard snapToCorners, let window = window, !window.styleMask.contains(.fullScreen), let screen = window.screen else {
			self.window?.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

			return
		}

		window.maxSize = NSSize(width: screen.visibleFrame.width * 0.75, height: screen.visibleFrame.height * 0.75)

		guard !isMoving, window.frame.snappedCorner(of: screen, with: snapInset) == nil else {
			return
		}

		var frame = window.frame
		frame.origin = frame.originForSnappingToPreferredCorner(of: screen, with: snapInset)

		if frame.size.width > window.maxSize.width {
			frame.size.width = window.maxSize.width
		}

		if frame.size.height > window.maxSize.height {
			frame.size.height = window.maxSize.height
		}

		window.setFrame(frame, display: false, animate: true)
	}

	var snapToCorners: Bool {
		get { return (UserDefaults.standard.object(forKey: WindowController.snapToCornersKey) as? NSNumber)?.boolValue ?? false }
		set {
			UserDefaults.standard.set(NSNumber(value: newValue), forKey: WindowController.snapToCornersKey)
			didSetSnapToCorners()
		}
	}

	@IBAction func toggleSnapToCorners(_ sender: Any?) {
		self.snapToCorners = !self.snapToCorners
	}

	// MARK: Picture In Picture

	@IBAction func togglePictureInPicture(_ sender: Any?) {
		if let vc = self.contentViewController as? ViewController {
			vc.togglePictureInPicture()
		}
	}

	// MARK: NSResponder

	private var isMoving = false

	override func mouseUp(with event: NSEvent) {
		super.mouseUp(with: event)

		guard isMoving else {
			return
		}

		isMoving = false

		guard !event.modifierFlags.contains(.command) else {
			return
		}

		didSetSnapToCorners()
	}

	// MARK: Window delegate

	func windowWillMove(_ notification: Notification) {
		isMoving = true
	}

	func windowDidMove(_ notification: Notification) {
		isMoving = true // Sometimes windowWillMove isn't called
	}

	func windowDidChangeScreen(_ notification: Notification) {
		didSetSnapToCorners()
	}

	func windowDidChangeBackingProperties(_ notification: Notification) {
		didSetSnapToCorners()
	}

	func windowDidEndLiveResize(_ notification: Notification) {
		didSetSnapToCorners()
	}

	func windowDidEnterFullScreen(_ notification: Notification) {
		guard let window = notification.object as? NSWindow else {
			return
		}

		fullscreenDelegate?.windowDidEnterFullScreen(window)
	}

	func windowDidFailToEnterFullScreen(_ window: NSWindow) {
		fullscreenDelegate?.windowDidFailToEnterFullScreen(window)
	}

	func windowDidExitFullScreen(_ notification: Notification) {
		didSetSnapToCorners()

		guard let window = notification.object as? NSWindow else {
			return
		}

		fullscreenDelegate?.windowDidExitFullScreen(window)
	}

	func windowDidFailToExitFullScreen(_ window: NSWindow) {
		fullscreenDelegate?.windowDidFailToExitFullScreen(window)
	}

}
