import Foundation

protocol PictureInPictureDelegate: AnyObject {
	func willEnterPictureInPicture(_ sender: Any?)

	func didEnterPictureInPicture(_ sender: Any?)

	func willExitPictureInPicture(_ sender: Any?)

	func didExitPictureInPicture(_ sender: Any?)
}
