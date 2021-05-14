import Cocoa
import WebKit

class ViewController: NSViewController {

	enum PlaybackStatus: String {
		case none = "none"
		case paused = "paused"
		case playing = "playing"
	}

	enum PIPStatus {
		case notInPIP
		case inPIP
		case intermediate
	}

	private weak var windowController: WindowController? {
		return view.window?.windowController as? WindowController
	}

	var webView: WebView!

	@IBOutlet weak var titleView: TitleView?

	@IBOutlet weak var activityIndicator: ActivityIndicator?

	@IBOutlet weak var pipOverlayView: NSVisualEffectView!

	private var currentNavigation: WKNavigation?

	private var pipStatus = PIPStatus.notInPIP
	private var playbackStatus: PlaybackStatus = .none

	lazy var pip: PIPViewController = {
		let pip = PIPViewController()
		pip.delegate = self
		return pip
	}()

	var pipViewVC: NSViewController!

	weak var pipDelegate: PictureInPictureDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.layer?.backgroundColor = NSColor(deviceRed: 0.078, green: 0.078, blue: 0.078, alpha: 1).cgColor
		pipOverlayView.isHidden = true

		titleView?.delegate = self

		let configuration = WKWebViewConfiguration()
		configuration.userContentController.add(self, name: "jellystyle")
		configuration.userContentController.add(self, name: "requestFullscreen")
		configuration.userContentController.add(self, name: "playback")
		configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

		webView = WebView(frame: view.frame, configuration: configuration)
		webView.isHidden = true
		webView.navigationDelegate = self
		webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"

		addWebViewToView()

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

	private func addWebViewToView() {
		webView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(webView, positioned: .below, relativeTo: titleView)
		view.addConstraints([
			webView.topAnchor.constraint(equalTo: view.topAnchor),
			webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			webView.leftAnchor.constraint(equalTo: view.leftAnchor),
			webView.rightAnchor.constraint(equalTo: view.rightAnchor),
		])
	}

	func resume() {
		webView.evaluateJavaScript("window.jellystyle.resume();", completionHandler: didEvaluateJavascript)
	}

	func pause() {
		webView.evaluateJavaScript("window.jellystyle.pause();", completionHandler: didEvaluateJavascript)
	}

	@IBAction func search(_ sender: Any?) {
		guard let webView = webView, !webView.isHidden else {
			return
		}

		webView.evaluateJavaScript("window.jellystyle.focusSearch();", completionHandler: didEvaluateJavascript)
	}

	func enterPictureInPicture() {
		guard playbackStatus != .none, pipStatus == .notInPIP, let webView = webView, !webView.isHidden else {
			return
		}

		pipDelegate?.willEnterPictureInPicture(self)
		pipOverlayView.isHidden = false
		pipStatus = .intermediate

		webView.evaluateJavaScript("window.jellystyle.setControlsVisibility(false);", completionHandler: didEvaluateJavascript)

		// wait for transition animation end
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
			let oldMinSize = self.pip.minSize
			let oldMaxSize = self.pip.maxSize

			self.pipViewVC = NSViewController()
			self.pipViewVC.view = webView
			self.pip.title = webView.title

			self.pip.minSize = webView.frame.size
			self.pip.maxSize = webView.frame.size

			webView.isInPipMode = true

			self.pip.presentAsPicture(inPicture: self.pipViewVC)

			webView.autoresizingMask = [.width, .height]
			webView.translatesAutoresizingMaskIntoConstraints = true
			webView.updateConstraints()

			if let view = webView.superview {
				view.addConstraints([
					webView.topAnchor.constraint(equalTo: view.topAnchor),
					webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
					webView.leftAnchor.constraint(equalTo: view.leftAnchor),
					webView.rightAnchor.constraint(equalTo: view.rightAnchor),
				])
			}

			self.pipStatus = .inPIP
			self.pipDelegate?.didEnterPictureInPicture(self)

			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
				self.pip.minSize = oldMinSize
				self.pip.maxSize = oldMaxSize
				self.windowController?.window?.miniaturize(self)
			}
		}
	}

	func exitPictureInPicture() {
		guard pipStatus == .inPIP else {
			return
		}

		if pipShouldClose(pip) {
			pip.dismiss(self.pipViewVC!)
		}
	}

	func togglePictureInPicture() {
		switch pipStatus {
		case .notInPIP:
			enterPictureInPicture()

		case .inPIP:
			exitPictureInPicture()

		case .intermediate:
			break
		}
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

		let value: String = titleView.isHidden ? "null" : String(format: "\"%1.1fpx\"", titleView.bounds.size.height)
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
		switch message.name {
		case "jellystyle":
			guard let dictionary = message.body as? [String: Any] else {
				print(message.name, message.body)
				return
			}

			displayingControls = (dictionary["controlsVisible"] as? NSNumber)?.boolValue ?? false
			displayingOverlay = (dictionary["overlayVisible"] as? NSNumber)?.boolValue ?? false
			displayingHeader = (dictionary["hasHeader"] as? NSNumber)?.boolValue ?? false
			canSearch = (dictionary["hasSearch"] as? NSNumber)?.boolValue ?? false

			if let size = dictionary["videoSize"] as? [NSNumber] {
				let aspectRatio = NSSize(width: size[0].doubleValue, height: size[1].doubleValue)
				windowController?.update(aspectRatio: aspectRatio)
				pip.aspectRatio = aspectRatio
			}
			else {
				windowController?.update(aspectRatio: nil)
			}

			titleView?.shouldHideWhenInactive = !(displayingControls || displayingHeader)

		case "requestFullscreen":
			guard
				let boolValue = (message.body as? NSNumber)?.boolValue,
				let window = view.window,
				window.styleMask.contains(.fullScreen) != boolValue
			else {
				print(message.name, message.body)
				return
			}

			window.toggleFullScreen(self)

		case "playback":
			guard
				let dictionary = message.body as? [String: Any],
				let status = PlaybackStatus(rawValue: String((dictionary["status"] as? NSString) ?? "none"))
			else {
				print(message.name, message.body)
				return
			}

			guard status != playbackStatus else {
				return
			}

			switch (playbackStatus, status) {
			case (_, .none):
				pip.playing = false
				exitPictureInPicture()

			case (_, .paused):
				pip.playing = false

			case (_, .playing):
				pip.playing = true
			}

			playbackStatus = status

		default:
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

extension ViewController: PIPViewControllerDelegate {

	private func preparePipClose() {
		pipDelegate?.willExitPictureInPicture(self)
		pipStatus = .intermediate
		pip.replacementView = view

		NSApp.activate(ignoringOtherApps: true)

		if let window = windowController?.window {
			window.deminiaturize(pip)

			var frame = window.frame
			frame.size = webView.frame.size
			window.setFrame(frame, display: true, animate: true)
		}
	}

	private func pipClosed() {
		addWebViewToView()
		pipOverlayView.isHidden = true
		pipStatus = .notInPIP
		webView.isInPipMode = false
		pipDelegate?.didExitPictureInPicture(self)
	}

	public func pipShouldClose(_ pip: PIPViewController) -> Bool {
		preparePipClose()
		return true
	}

	public func pipWillClose(_ pip: PIPViewController) {
		preparePipClose()
	}

	public func pipDidClose(_ pip: PIPViewController) {
		pipClosed()
	}

	public func pipActionPlay(_ pip: PIPViewController) {
		resume()
	}

	public func pipActionPause(_ pip: PIPViewController) {
		pause()
	}

	public func pipActionStop(_ pip: PIPViewController) {
		pause()
	}

}
