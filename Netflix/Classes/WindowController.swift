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

extension NSWindow {

	func preferredCorner(for screen: NSScreen) -> NSRect.Corner {
		return frame.preferredCorner(for: screen)
	}

	func originForSnappingToPreferredCorner(of screen: NSScreen, with insets: NSRect.Corner.Insets = .zero) -> NSPoint {
		return frame.originForSnappingToPreferredCorner(of: screen, with: insets)
	}

	func originForSnapping(to corner: NSRect.Corner, of screen: NSScreen, with insets: NSRect.Corner.Insets = .zero) -> NSPoint {
		return frame.originForSnapping(to: corner, of: screen, with: insets)
	}

}
