import Cocoa

@IBDesignable
class ActivityIndicator: NSView {

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		initialize()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		initialize()
	}

	private var imageLayer: CALayer?

	private func initialize() {
		wantsLayer = true
		layerContentsRedrawPolicy = .onSetNeedsDisplay

		guard let layer = layer else {
			return
		}

		let sublayer = CALayer()
		sublayer.contents = NSImage(named: NSImage.Name("site-spinner"))
		sublayer.frame = bounds
		layer.addSublayer(sublayer)
		imageLayer = sublayer

		let angle: CGFloat = 0 - 360 * .pi / 180

		let transform = CATransform3DRotate(sublayer.transform, angle, 0, 0, 1)
		sublayer.transform = transform

		let animation = CABasicAnimation(keyPath: "transform.rotation")
		animation.duration = 0.9
		animation.fromValue = 0
		animation.toValue = angle
		animation.repeatCount = .greatestFiniteMagnitude
		sublayer.add(animation, forKey: "transform.rotation")
	}

	override var frame: NSRect {
		didSet { setNeedsDisplay(bounds) }
	}

	override func updateLayer() {
		super.updateLayer()

		guard let layer = layer else {
			return
		}

		let diameter = min(layer.bounds.size.width, layer.bounds.size.height)
		let x = (layer.bounds.size.width - diameter) / 2
		let y = (layer.bounds.size.height - diameter) / 2
		imageLayer?.frame = CGRect(x: x, y: y, width: diameter, height: diameter)
	}

}
