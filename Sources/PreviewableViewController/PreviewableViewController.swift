import Foundation

@objc public protocol PreviewableViewController {
	var previewActions: [KKPreviewAction] { get }
}

public extension KKPreviewModel {
	convenience init<T: UIViewController & PreviewableViewController>(previewingViewController: T, originatedFrom: CGRect? = nil, commit: KKPreviewCommit) {
		self.init(previewingViewController: previewingViewController, originatedFrom: originatedFrom, actions: previewingViewController.previewActions, commit: commit)
	}
}
