@available(swift, deprecated: 1)
@objc public protocol PreviewableViewController {
	var previewActions: [Action] { get }
}

import CompatibleContextMenuInteraction
public extension CompatibleContextMenuInteraction.Model {
	init<T: UIViewController & PreviewableViewController>(previewingViewController: T, originatedFrom: CGRect? = nil, commit: Commit) {
		self.init(previewingViewController: previewingViewController, originatedFrom: originatedFrom, actions: previewingViewController.previewActions.map { .init($0) }, commit: commit)
	}
}
