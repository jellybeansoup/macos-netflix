import Cocoa
import WebKit

class ViewController: NSViewController {

	private weak var windowController: WindowController? {
		return view.window?.windowController as? WindowController
	}

	var webView: WKWebView!

	@IBOutlet weak var titleView: TitleView?

	@IBOutlet weak var activityIndicator: ActivityIndicator?

	private var currentNavigation: WKNavigation?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.layer?.backgroundColor = NSColor(deviceRed: 0.078, green: 0.078, blue: 0.078, alpha: 1).cgColor

		titleView?.delegate = self

		let configuration = WKWebViewConfiguration()
		configuration.userContentController.add(self, name: "jellystyle")
		configuration.userContentController.add(self, name: "requestFullscreen")

		webView = WKWebView(frame: view.frame, configuration: configuration)
		webView.isHidden = true
		webView.navigationDelegate = self
		webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"

		webView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(webView, positioned: .below, relativeTo: titleView)
		view.addConstraints([
			webView.topAnchor.constraint(equalTo: view.topAnchor),
			webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			webView.leftAnchor.constraint(equalTo: view.leftAnchor),
			webView.rightAnchor.constraint(equalTo: view.rightAnchor),
		])

//		let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
//		webView.configuration.websiteDataStore.removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: {})

		guard let url = URL(string: "https://www.netflix.com/browse") else {
			return
		}

		let request = URLRequest(url: url)

		guard let navigation = webView.load(request) else {
			return
		}

		currentNavigation = navigation
	}

	override func viewWillAppear() {
		super.viewWillAppear()

		windowController?.fullscreenDelegate = self
	}

	internal fileprivate(set) var displayingHeader = true

	internal fileprivate(set) var displayingControls = false

	internal fileprivate(set) var displayingOverlay = false

	internal fileprivate(set) var canSearch = false

	@IBAction func search(_ sender: Any?) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.focusSearch();", completionHandler: didEvaluateJavascript)
	}

}

class ViewControllerView: NSView {

	override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
		return true
	}

}

extension ViewController: TitleViewDelegate {

	func titleViewDidChangeVisibility(_ titleView: TitleView) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		let value: String = titleView.isHidden ? "null" : "\"22px\""
		webView.evaluateJavaScript("window.jellystyle.setTitleViewInset(\(value));", completionHandler: didEvaluateJavascript)

		if let window = view.window, !window.styleMask.contains(.fullScreen) {
			window.standardWindowButton(.closeButton)?.superview?.isHidden = titleView.isHidden
		}
	}

}

extension ViewController: WindowControllerFullscreenDelegate {

	func windowDidEnterFullScreen(_ window: NSWindow) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.windowDidEnterFullScreen(true);", completionHandler: didEvaluateJavascript)
	}

	func windowDidFailToEnterFullScreen(_ window: NSWindow) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.windowDidEnterFullScreen(false);", completionHandler: didEvaluateJavascript)
	}

	func windowDidExitFullScreen(_ window: NSWindow) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.windowDidExitFullScreen(true);", completionHandler: didEvaluateJavascript)
	}

	func windowDidFailToExitFullScreen(_ window: NSWindow) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.windowDidExitFullScreen(false);", completionHandler: didEvaluateJavascript)
	}

}

extension ViewController: WKScriptMessageHandler {

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		if message.name == "jellystyle", let dictionary = message.body as? [String: Any] {
			displayingControls = (dictionary["controlsVisible"] as? NSNumber)?.boolValue ?? false
			displayingOverlay = (dictionary["overlayVisible"] as? NSNumber)?.boolValue ?? false
			displayingHeader = (dictionary["hasHeader"] as? NSNumber)?.boolValue ?? false
			canSearch = (dictionary["hasSearch"] as? NSNumber)?.boolValue ?? false

			if let size = dictionary["videoSize"] as? [NSNumber] {
				let aspectRatio = NSSize(width: size[0].doubleValue, height: size[1].doubleValue)
				windowController?.update(aspectRatio: aspectRatio)
			}
			else {
				windowController?.update(aspectRatio: nil)
			}

			titleView?.shouldHideWhenInactive = !(displayingControls || displayingHeader)
		}
		else if message.name == "requestFullscreen", let boolValue = (message.body as? NSNumber)?.boolValue, let window = view.window {
			guard window.styleMask.contains(.fullScreen) != boolValue else {
				return
			}

			window.toggleFullScreen(self)
		}
		else {
			print(message.name, message.body)
		}
	}

}

extension ViewController: WKNavigationDelegate {

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		activityIndicator?.isHidden = !webView.isHidden
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		activityIndicator?.isHidden = true
		webView.isHidden = false

		guard let scriptURL = Bundle.main.url(forResource: "Customization", withExtension: "js"), let script = try? String(contentsOf: scriptURL) else {
			return
		}

		webView.evaluateJavaScript(script, completionHandler: {
			self.didLoadCustomizationJavascript($0, $1)
			self.didEvaluateJavascript($0, $1)
		})
	}

	private func didLoadCustomizationJavascript(_ response: Any?, _ error: Error?) {
		if let titleView = self.titleView {
			self.titleViewDidChangeVisibility(titleView)
		}

		if let window = self.view.window, window.styleMask.contains(.fullScreen) {
			self.windowDidEnterFullScreen(window)
		}
	}

	private func didEvaluateJavascript(_ response: Any?, _ error: Error?) {
		if let error = error {
			print(error)
		}
		else if let response = response {
			print(response)
		}
	}

}
