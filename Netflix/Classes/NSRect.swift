import Cocoa

extension NSRect {

	struct Corner: CustomStringConvertible {
		var x: Alignment = .leading
		var y: Alignment = .leading

		enum Alignment: CustomStringConvertible {
			case leading
			case trailing

			static var left = Alignment.leading
			static var right = Alignment.trailing
			static var bottom = Alignment.leading
			static var top = Alignment.trailing

			var description: String {
				switch self {
				case .leading: return "leading"
				case .trailing: return "trailing"
				}
			}

		}

		struct Insets: CustomStringConvertible {
			var x: CGFloat = 0
			var y: CGFloat = 0

			static let zero = Insets(x: 0, y: 0)

			var description: String {
				return "(x = \(x), y = \(y))"
			}

		}

		var description: String {
			return "(x = \(x), y = \(y))"
		}

	}

	func preferredCorner(for screen: NSScreen) -> NSRect.Corner {
		var corner = NSRect.Corner()

		let left = minX - screen.visibleFrame.minX
		let right = screen.visibleFrame.maxX - maxX
		corner.x = left < right ? .leading : .trailing

		let bottom = minY - screen.visibleFrame.minY
		let top = screen.visibleFrame.maxY - maxY
		corner.y = bottom > top ? .trailing : .leading

		return corner
	}

	func originForSnappingToPreferredCorner(of screen: NSScreen, with insets: NSRect.Corner.Insets = .zero) -> NSPoint {
		return size.originForSnapping(to: preferredCorner(for: screen), of: screen, with: insets)
	}

	func originForSnapping(to corner: NSRect.Corner, of screen: NSScreen, with insets: NSRect.Corner.Insets = .zero) -> NSPoint {
		return size.originForSnapping(to: corner, of: screen, with: insets)
	}

}

extension NSSize {

	func originForSnapping(to corner: NSRect.Corner, of screen: NSScreen, with insets: NSRect.Corner.Insets = .zero) -> NSPoint {
		var origin: NSPoint = .zero

		switch corner.x {
		case .leading: origin.x = screen.visibleFrame.minX + insets.x
		case .trailing: origin.x = screen.visibleFrame.maxX - (width + insets.x)
		}

		switch corner.y {
		case .leading: origin.y = screen.visibleFrame.minY + insets.y
		case .trailing: origin.y = screen.visibleFrame.maxY - (height + insets.y)
		}

		return origin
	}

}
