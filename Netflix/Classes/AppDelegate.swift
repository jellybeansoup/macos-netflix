import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	static weak var shared: AppDelegate? = {
		return NSApplication.shared.delegate as? AppDelegate
	}()

	// MARK: Accessing various classes

	private weak var defaultWindowController: WindowController? {
		guard let window = NSApplication.shared.mainWindow else {
			return nil
		}

		guard let windowController = window.windowController as? WindowController else {
			return nil
		}

		return windowController
	}

	private weak var defaultViewController: ViewController? {
		guard let window = NSApplication.shared.mainWindow else {
			return nil
		}

		guard let viewController = window.contentViewController as? ViewController else {
			return nil
		}

		return viewController
	}

	// MARK: Menu actions

	@IBOutlet weak var searchMenuItem: NSMenuItem?

	@IBOutlet weak var keepInFrontMenuItem: NSMenuItem?

	@IBOutlet weak var snapToCornersMenuItem: NSMenuItem?

	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if let searchMenuItem = searchMenuItem, menuItem === searchMenuItem {
			return defaultViewController?.canSearch ?? false
		}
		else if let keepInFrontMenuItem = keepInFrontMenuItem, menuItem === keepInFrontMenuItem {
			menuItem.state = (defaultWindowController?.keepInFront ?? true) ? .on : .off
		}
		else if let snapToCornersMenuItem = snapToCornersMenuItem, menuItem === snapToCornersMenuItem {
			menuItem.state = (defaultWindowController?.snapToCorners ?? true) ? .on : .off
		}

		return true
	}

	@IBAction func about(_ sender: Any?) {
		NSApplication.shared.orderFrontStandardAboutPanel(options: [
			.applicationName: "Netflix wrapper for macOS",
			NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "",
		])
	}

	@IBAction func search(_ sender: Any?) {
		defaultViewController?.search(sender)
	}

	@IBAction func reload(_ sender: Any?) {
		defaultViewController?.webView?.reload(sender)
	}

	@IBAction func actualSize(_ sender: Any?) {
		defaultViewController?.webView?.magnification = 1.0
	}

	@IBAction func zoomIn(_ sender: Any?) {
		defaultViewController?.webView?.magnification += 0.1
	}

	@IBAction func zoomOut(_ sender: Any?) {
		defaultViewController?.webView?.magnification -= 0.1
	}

	@IBAction func keepInFront(_ sender: Any?) {
		defaultWindowController?.toggleKeepInFront(sender)
	}

	@IBAction func snapToCorners(_ sender: Any?) {
		defaultWindowController?.toggleSnapToCorners(sender)
	}

	@IBAction func github(_ sender: Any?) {
		guard let url = URL(string: "https://github.com/jellybeansoup/macos-netflix") else {
			fatalError("Could not prepare URL for GitHub Repository")
		}

		NSWorkspace.shared.open(url)
	}

	@IBAction func help(_ sender: Any?) {
		guard let url = URL(string: "https://help.netflix.com/en") else {
			fatalError("Could not prepare URL for Netflix Help")
		}

		NSWorkspace.shared.open(url)
	}

}
