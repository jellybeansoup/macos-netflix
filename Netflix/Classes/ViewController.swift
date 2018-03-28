import Cocoa
import WebKit

class ViewController: NSViewController {

	@IBOutlet weak var webView: WKWebView?

	@IBOutlet weak var titleView: TitleView?

	@IBOutlet weak var activityIndicator: ActivityIndicator?

	private var currentNavigation: WKNavigation?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.layer?.backgroundColor = NSColor(deviceRed: 0.078, green: 0.078, blue: 0.078, alpha: 1).cgColor

		guard let webView = webView else {
			return
		}

		webView.isHidden = true
		webView.navigationDelegate = self
		webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"
		webView.configuration.userContentController.add(self, name: "jellystyle")

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

	internal fileprivate(set) var displayingHeader = true

	internal fileprivate(set) var displayingControls = false

	internal fileprivate(set) var displayingOverlay = false

	internal fileprivate(set) var canSearch = false

	@IBAction func search(_ sender: Any?) {
		webView?.evaluateJavaScript("window.jellystyle.focusSearch();", completionHandler: didEvaluateJavascript)
	}

}

class ViewControllerView: NSView {

	override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
		return true
	}

}

extension ViewController: WKScriptMessageHandler {

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		guard let dictionary = message.body as? [String: Any] else {
			return
		}

		displayingControls = (dictionary["controlsVisible"] as? NSNumber)?.boolValue ?? false
		displayingOverlay = (dictionary["overlayVisible"] as? NSNumber)?.boolValue ?? false
		displayingHeader = (dictionary["hasHeader"] as? NSNumber)?.boolValue ?? false
		canSearch = (dictionary["hasSearch"] as? NSNumber)?.boolValue ?? false

		titleView?.shouldHideWhenInactive = !(displayingControls || displayingHeader)
	}

}

extension ViewController: WKNavigationDelegate {

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		activityIndicator?.isHidden = !webView.isHidden
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		activityIndicator?.isHidden = true
		webView.isHidden = false

		if let scriptURL = Bundle.main.url(forResource: "Customization", withExtension: "js"), let script = try? String(contentsOf: scriptURL) {
			webView.evaluateJavaScript(script, completionHandler: didEvaluateJavascript)
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
