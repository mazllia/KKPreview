import UIKit
@objcMembers class KKPreviewModel: NSObject {
	let previewingViewController: UIViewController
	// FIXME: deal with `.null` value
	/// For Objective-C compatibility, `.null` means nil
	let originatedFrom: CGRect
	let actions: [KKPreviewAction]
	init(previewing viewController: UIViewController, originatedFrom: CGRect = .null, actions: [KKPreviewAction] = []) {
		self.previewingViewController = viewController
		self.originatedFrom = originatedFrom
		self.actions = actions
		super.init()
	}
}

@objcMembers class KKPreviewModelForTableView: KKPreviewModel {
	let pointInCell: CGPoint
	let indexPath: IndexPath
	
	init(_ mode: KKPreviewModel, indexPath: IndexPath, pointInCell: CGPoint) {
		self.indexPath = indexPath
		self.pointInCell = pointInCell
		super.init(previewing: mode.previewingViewController, originatedFrom: mode.originatedFrom, actions: mode.actions)
	}
}

/// TODO: remove UIPreviewActionItem conformance as UIKit definitly misuse the design of protocol
@objcMembers class KKPreviewAction: NSObject, UIPreviewActionItem {
	typealias Handler = () -> Void
	let title: String
	let destructive: Bool
	let handler: Handler
	init(title: String, destructive: Bool = false, handler: @escaping Handler) {
		self.title = title
		self.destructive = destructive
		self.handler = handler
		super.init()
	}
}

struct CompatibleContextMenuInteraction {
    var text = "Hello, World!"
}
