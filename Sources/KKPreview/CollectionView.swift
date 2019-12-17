import Foundation

// MARK: UIViewControllerPreviewingDelegate
extension UICollectionView: UIViewControllerPreviewingDelegate {
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard
			let storage = associateValue,
			let cellInfo = convert(location),
			let model = storage.delegate?.model(in: self, on: cellInfo.indexPath, at: cellInfo.location) else { return nil }
		storage.model = IndexedViewCellModel(model: model, indexPath: cellInfo.indexPath, pointInCell: cellInfo.location)
		
		if let sourceRect = model.originatedFrom {
			previewingContext.sourceRect = sourceRect
		}
		return model.previewingViewController
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard
			let storage = associateValue,
			let delegate = storage.delegate,
			let model = storage.model else { return }
		assert(model.model.previewingViewController === viewControllerToCommit)
		commit(delegate: delegate, model: model.model)
	}
}

// MARK: UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
extension UICollectionView: UIContextMenuInteractionDelegate {
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard
			let storage = associateValue,
			let cellInfo = convert(location),
			let model = storage.delegate?.model(in: self, on: cellInfo.indexPath, at: cellInfo.location) else { return nil }
		storage.model = IndexedViewCellModel(model: model, indexPath: cellInfo.indexPath, pointInCell: cellInfo.location)
		
		return .init(identifier: nil,
					 previewProvider: { model.previewingViewController },
					 actionProvider: { _ in UIMenu(actions: model.actions) }
		)
	}
	
	private var targetedPreview: UITargetedPreview? {
		guard
			let model = associateValue?.model,
			let cell = cellForItem(at: model.indexPath) else { return nil }
		
		if let originatedRect = model.model.originatedFrom {
			return .init(view: cell, rounded: originatedRect)
		} else {
			return .init(view: cell)
		}
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard
			let storage = associateValue,
			let delegate = storage.delegate,
			let model = storage.model else { return }
		assert(model.model.previewingViewController === animator.previewViewController)
		commit(delegate: delegate, model: model.model)
	}
}

private extension UICollectionView {
	/// - parameter location: location in table view
	/// - returns: point in cell and index path of such cell
	func convert(_ location: CGPoint) -> (indexPath: IndexPath, location: CGPoint)? {
		guard
			let indexPath = indexPathForItem(at: location),
			let cell = cellForItem(at: indexPath) else { return nil }
		return (indexPath, convert(location, to: cell))
	}
	
	func commit(delegate: CollectionViewDelegate, model: KKPreviewModel) {
		let viewController = model.previewingViewController
		switch model.commit.style {
		case .show: delegate.show(viewController, sender: self)
		case .showDetail: delegate.showDetailViewController(viewController, sender: self)
		case .custom: model.commit.handler?(viewController)
		}
	}
}
