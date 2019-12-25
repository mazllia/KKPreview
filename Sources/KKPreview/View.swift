import Foundation

// MARK: UIViewControllerPreviewingDelegate
@objc extension UIView: UIViewControllerPreviewingDelegate {
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let model = askDelegateToUpdateStoredPreviewModel(at: location) else { return nil }
		if let sourceRect = model.originatedFrom {
			previewingContext.sourceRect = sourceRect
		}
		return model.previewingViewController
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard
			let storage: InteractivePreviewStorage = viewStorage,
			let model = storage.model?.model else { return }
		assert(model.previewingViewController === viewControllerToCommit)
		storage.presentingViewController?.commit(model)
		storage.model = nil
	}
}

// MARK: UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
@objc extension UIView: UIContextMenuInteractionDelegate {
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard let model = askDelegateToUpdateStoredPreviewModel(at: location) else { return nil }
		return .init(identifier: nil,
					 previewProvider: { model.previewingViewController },
					 actionProvider: { _ in UIMenu(actions: model.actions) }
		)
	}
	
	var targetedPreview: UITargetedPreview? {
		guard
			let model = viewStorage?.model,
			let rect = model.model.originatedFrom else { return nil }
		
		return .init(view: self, rounded: rect)
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
		assert(model.previewingViewController === animator.previewViewController)
		animator.addCompletion {
			storage.presentingViewController?.commit(model)
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
