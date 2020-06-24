import Foundation
import UIKit

// MARK: UIViewControllerPreviewingDelegate
@objc extension UIView: UIViewControllerPreviewingDelegate {
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let model = askDelegateToUpdateStoredPreviewModel(at: location) else { return nil }
		if let sourceRect = model.originatedFrom {
			previewingContext.sourceRect = sourceRect
		}
		defer { model.previewingViewController = nil }
		return model.previewingViewController
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard
			let storage: InteractivePreviewStorage = viewStorage,
			let model = storage.model?.model else { return }
		storage.presentingViewController?.commit(model.commit, to: viewControllerToCommit)
		storage.model = nil
	}
}

// MARK: UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
@objc extension UIView: UIContextMenuInteractionDelegate {
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard let model = askDelegateToUpdateStoredPreviewModel(at: location) else { return nil }
		defer { model.previewingViewController = nil }
		return .init(identifier: nil,
					 previewProvider: { [previewingViewController = model.previewingViewController] in previewingViewController },
					 actionProvider: { _ in UIMenu(actions: model.actions) }
		)
	}
	
	var targetedPreview: UITargetedPreview? {
		guard let model = viewStorage?.model else { return nil }
		return .init(view: self, rounded: model.model.originatedFrom)
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard
			let storage: InteractivePreviewStorage = viewStorage,
			let model = storage.model?.model else { return }
		animator.addCompletion {
			if let viewControllerToCommit = animator.previewViewController {
				storage.presentingViewController?.commit(model.commit, to: viewControllerToCommit)
			}
			storage.model = nil
		}
	}
}

@objc extension UIView {
	/// - returns: the updated preview model
	func askDelegateToUpdateStoredPreviewModel(at location: CGPoint) -> KKPreviewModel? {
		guard
			let storage = viewStorage,
			let model = storage.delegate?.view(self, modelAt: location) else { return nil }
		storage.model = .init(model: model, point: location)
		return model
	}
}
