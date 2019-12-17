import Foundation

@objc public protocol PreviewableViewController {
	var previewActions: [KKPreviewAction] { get }
}

public extension KKPreviewModel {
	convenience init<T: UIViewController & PreviewableViewController>(previewableViewController: T, originatedFrom: CGRect? = nil, commit: KKPreviewCommit) {
		self.init(previewingViewController: previewableViewController, originatedFrom: originatedFrom, actions: previewableViewController.previewActions, commit: commit)
	}	
}
