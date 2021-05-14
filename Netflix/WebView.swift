import Cocoa
import WebKit

class WebView: WKWebView {
	var isInPipMode = false

	override public func mouseDown(with event: NSEvent) {
		if isInPipMode {
			window?.performDrag(with: event)
		} else {
			super.mouseDown(with: event)
		}
	}
}
