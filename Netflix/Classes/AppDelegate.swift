import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	static weak var shared: AppDelegate? = {
		return NSApplication.shared.delegate as? AppDelegate
	}()

	// MARK: Accessing various classes

	private weak var defaultViewController: ViewController? {
		guard let window = NSApplication.shared.keyWindow else {
			return nil
		}

		guard let viewController = window.contentViewController as? ViewController else {
			return nil
		}

		return viewController
	}

	// MARK: Menu actions

	@IBOutlet weak var searchMenuItem: NSMenuItem?

	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if let searchMenuItem = searchMenuItem, menuItem === searchMenuItem {
			return defaultViewController?.canSearch ?? false
		}

		return super.validateMenuItem(menuItem)
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
