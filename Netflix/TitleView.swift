import Cocoa

class TitleView: NSVisualEffectView {

	var shouldHideWhenInactive: Bool = false {
		didSet { updateVisibility() }
	}

	override var mouseDownCanMoveWindow: Bool {
		return true
	}

	override func hitTest(_ point: NSPoint) -> NSView? {
		guard self.frame.contains(point) else {
			return nil
		}

		return self.superview
	}

	private var keyWindowObservers: [Any]?

	override func viewWillMove(toWindow newWindow: NSWindow?) {
		keyWindowObservers?.forEach { NotificationCenter.default.removeObserver($0) }
		keyWindowObservers = nil
	}

	override func viewDidMoveToWindow() {
		let becomeKey = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] notification in
			self?.updateVisibility()
		}

		let resignKey = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { [weak self] notification in
			self?.updateVisibility()
		}

		keyWindowObservers = [becomeKey, resignKey]
		updateVisibility()
	}

	private func updateVisibility() {
		guard let window = window else {
			return
		}

		isHidden = shouldHideWhenInactive && !window.isKeyWindow
		window.standardWindowButton(.closeButton)?.superview?.isHidden = isHidden
	}

}
