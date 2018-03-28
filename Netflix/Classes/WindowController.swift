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
	}

}
