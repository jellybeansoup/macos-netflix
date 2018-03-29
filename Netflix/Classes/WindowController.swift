import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

	override func windowDidLoad() {
		super.windowDidLoad()

		guard let window = window else {
			return
		}

		window.delegate = self
		window.title = ""
		window.styleMask.insert(.fullSizeContentView)
		window.titlebarAppearsTransparent = true
		window.isMovableByWindowBackground = true

		window.setContentSize(NSSize(width: 1280, height: 904))
		window.contentMinSize = NSSize(width: 640, height: 360)

		didSetKeepInFront()
		didSetSnapToCorners()
	}

	// MARK: Lock aspect ratio in videos

	func update(aspectRatio: NSSize?) {
		guard let window = window, let screen = window.screen else {
			return
		}

		if let aspectRatio = aspectRatio {
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

	private var isMoving = false

	private let snapInset = NSRect.Corner.Insets(x: 20, y: 20)

	private func didSetSnapToCorners() {
		guard snapToCorners, let window = window, let screen = window.screen else {
			return
		}

		var frame = window.frame
		frame.origin = frame.originForSnappingToPreferredCorner(of: screen, with: snapInset)
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

	// MARK: NSResponder

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

	func windowDidEndLiveResize(_ notification: Notification) {
		didSetSnapToCorners()
	}

}
