import Cocoa

class WindowController: NSWindowController {

	override func windowDidLoad() {
		super.windowDidLoad()

		guard let window = window else {
			return
		}

		window.title = ""
		window.styleMask.insert(.fullSizeContentView)
		window.titlebarAppearsTransparent = true
		window.isMovableByWindowBackground = true

		window.setContentSize(NSSize(width: 1280, height: 904))
		window.contentMinSize = NSSize(width: 640, height: 360)

		didSetKeepInFront()
	}

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

}
