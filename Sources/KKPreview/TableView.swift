import Foundation

// MARK: UIViewControllerPreviewingDelegate
@objc extension UITableView {
	public override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard
			let storage: InteractivePreviewStorage = indexViewStorage ?? viewStorage,
			let model = storage.model?.model else { return }
		assert(model.previewingViewController === viewControllerToCommit)
		storage.presentingViewController?.commit(model)
		storage.model = nil
	}
}

// MARK: UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
@objc extension UITableView {
	public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard let model = askDelegateToUpdateStoredPreviewModel(at: location) else { return nil }
		return .init(identifier: nil,
					 previewProvider: { model.previewingViewController },
					 actionProvider: { _ in UIMenu(actions: model.actions) }
		)
	}
	
	override var targetedPreview: UITargetedPreview? {
		guard
			let storage: InteractivePreviewStorage = (indexViewStorage ?? viewStorage),
			let model = storage.model,
			let rect = model.model.originatedFrom else { return nil }
		
		let cell = convert(model.point)?.cell
		return .init(view: cell ?? self, rounded: rect)
	}
	
	public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}

	public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard
			let storage: InteractivePreviewStorage = indexViewStorage ?? viewStorage,
			let model = storage.model?.model else { return }
		assert(model.previewingViewController === animator.previewViewController)
		animator.addCompletion {
			storage.presentingViewController?.commit(model)
			storage.model = nil
		}
	}
}

@objc extension UITableView {
	/// - returns: the updated preview model
	override func askDelegateToUpdateStoredPreviewModel(at location: CGPoint) -> KKPreviewModel? {
		switch (indexViewStorage, viewStorage, convert(location)) {
		case (nil, nil, _): return nil
		case let (storage?, _, .some(cell)):
			guard
				let delegate = storage.delegate,
				let previewModel = delegate.indexedView(self, modelOn: cell.indexPath, at: cell.location) ?? delegate.view?(self, modelAt: location) else { return nil }
			storage.model = .init(model: previewModel, point: location)
			return previewModel
			
		case let (storage?, _, nil):
			guard
				let delegate = storage.delegate,
				let previewModel = delegate.view?(self, modelAt: location) else { return nil }
			storage.model = .init(model: previewModel, point: location)
			return previewModel
			
		case let (nil, storage?, _):
			guard
				let delegate = storage.delegate,
				let previewModel = delegate.view(self, modelAt: location) else { return nil }
			storage.model = .init(model: previewModel, point: location)
			return previewModel
		}
	}
}
