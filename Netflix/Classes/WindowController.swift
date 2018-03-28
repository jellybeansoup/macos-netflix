import Cocoa

class WindowController: NSWindowController {

	override func windowDidLoad() {
		super.windowDidLoad()

		window?.title = ""
		window?.styleMask.insert(.fullSizeContentView)
		window?.titlebarAppearsTransparent = true
		window?.isMovableByWindowBackground = true
	}

}
