import UIKit

// MARK: - Model -
public struct Model {
	public let previewingViewController: UIViewController
	public let originatedFrom: CGRect?
	
	public struct Action {
		public typealias Handler = () -> Void
		public let title: String
		public let destructive: Bool
		public let handler: Handler
		
		public init(title: String, destructive: Bool = false, handler: @escaping Handler) {
			self.title = title
			self.destructive = destructive
			self.handler = handler
		}
	}
	public let actions: [Action]
	
	public enum Commit {
		public typealias Handler = (UIViewController) -> Void
		case show, showDetail, custom(Handler?)
	}
	public let commit: Commit
	
	public init(previewingViewController: UIViewController, originatedFrom: CGRect? = nil, actions: [Action] = [], commit: Commit) {
		self.previewingViewController = previewingViewController
		self.originatedFrom = originatedFrom
		self.actions = actions
		self.commit = commit
	}
}

struct IndexedViewCellModel {
	let model: Model
	let indexPath: IndexPath
	let pointInCell: CGPoint
}

// MARK: Bridge
public extension UIPreviewAction {
	convenience init(_ action: Model.Action) {
		self.init(title: action.title, style: action.destructive ? .destructive : .default) { _, _ in action.handler() }
	}
}

@available(iOS 13, *)
public extension UIAction {
	convenience init(_ action: Model.Action) {
		self.init(title: action.title, attributes: action.destructive ? [.destructive] : []) { _ in action.handler() }
	}
}

@available(iOS 13, *)
public extension UIMenu {
	convenience init(actions: [Model.Action]) {
		self.init(title: "", children: actions.map { UIAction($0) })
	}
}

@available(iOS 13, *)
public extension UITargetedPreview {
	@objc convenience init(view: UIView, rounded rect: CGRect, cornerRadius: CGFloat = 3) {
		let parameters = UIPreviewParameters()
		parameters.visiblePath = .init(roundedRect: rect, cornerRadius: cornerRadius)
		parameters.backgroundColor = .clear
		
		self.init(view: view, parameters: parameters)
	}
}

// TODO: rewrite in objective-c to make swift unavialable
@available(*, unavailable, renamed: "Model.Action")
@objcMembers final public class CompatibleContextMenuModelAction: NSObject {
	public typealias Handler = () -> Void
	public let title: String
	public let destructive: Bool
	public let handler: Handler
	public init(title: String, destructive: Bool = false, handler: @escaping Handler) {
		self.title = title
		self.destructive = destructive
		self.handler = handler
		super.init()
	}
}


// MARK: - Compatible Protocols -
// MARK: - UIView
public protocol ViewDelegate {
	func model(in view: UIView, at point: CGPoint) -> Model?
}

public protocol CompatibleContextMenuView: UIView {
	func registerForCompatibleContextMenu(with delegate: ViewDelegate)
}

// MARK: - UITableView
public protocol TableViewDelegate: UITableViewController {
	func model(in tableView: UITableView, on indexPath: IndexPath, at pointInCell: CGPoint) -> Model?
}

public extension UITableView {
	var compatibleContextMenuDelegate: TableViewDelegate? {
		get { storage?.delegate }
		set {
			guard compatibleContextMenuDelegate !== newValue else { return }
			
			if let storage = storage {
				storage.delegate.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeInteraction(UIContextMenuInteraction(delegate: self))
				}
			}
			
			guard let newValue = newValue else {
				return storage = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			storage = Storage(delegate: newValue, context: context)
		}
	}
}

// MARK: Storage
private extension UITableView {
	typealias StorageType = Storage<TableViewDelegate>
	private static var contextMenuStorage = [UITableView: StorageType]()
	var storage: StorageType? {
		get { Self.contextMenuStorage[self] }
		set { Self.contextMenuStorage[self] = newValue }
	}
}

// MARK: Convenient Functions
private extension UITableView {
	func commit(delegate: TableViewDelegate, model: Model) {
		let viewController = model.previewingViewController
		switch model.commit {
		case .show: delegate.show(viewController, sender: self)
		case .showDetail: delegate.showDetailViewController(viewController, sender: self)
		case let .custom(handler): handler?(viewController)
		}
	}
	
	@available(iOS 13.0, *)
	var targetedPreview: UITargetedPreview? {
		guard
			let model = storage?.model,
			let cell = cellForRow(at: model.indexPath) else { return nil }
		
		if let originatedRect = model.model.originatedFrom {
			return .init(view: cell, rounded: originatedRect)
		} else {
			return .init(view: cell)
		}
	}
}

// MARK: UIViewControllerPreviewingDelegate
extension UITableView: UIViewControllerPreviewingDelegate {
	/// - parameter location: location in table view
	/// - returns: point in cell and index path of such cell
	private func convert(_ location: CGPoint) -> (indexPath: IndexPath, location: CGPoint)? {
		guard
			let indexPath = indexPathForRow(at: location),
			let cell = cellForRow(at: indexPath) else { return nil }
		return (indexPath, convert(location, to: cell))
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard
			let storage = storage,
			let cellInfo = convert(location),
			let model = storage.delegate.model(in: self, on: cellInfo.indexPath, at: cellInfo.location) else { return nil }
		storage.model = IndexedViewCellModel(model: model, indexPath: cellInfo.indexPath, pointInCell: cellInfo.location)
		
		if let sourceRect = model.originatedFrom {
			previewingContext.sourceRect = sourceRect
		}
		return model.previewingViewController
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard
			let storage = storage,
			let model = storage.model else { return }
		assert(model.model.previewingViewController === viewControllerToCommit)
		commit(delegate: storage.delegate, model: model.model)
	}
}

// MARK: UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
extension UITableView: UIContextMenuInteractionDelegate {
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard
			let storage = storage,
			let cellInfo = convert(location),
			let model = storage.delegate.model(in: self, on: cellInfo.indexPath, at: cellInfo.location) else { return nil }
		storage.model = IndexedViewCellModel(model: model, indexPath: cellInfo.indexPath, pointInCell: cellInfo.location)
		
		return .init(identifier: nil,
					 previewProvider: { model.previewingViewController },
					 actionProvider: { _ in UIMenu(actions: model.actions) }
		)
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		targetedPreview
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard
			let storage = storage,
			let model = storage.model else { return }
		assert(model.model.previewingViewController === animator.previewViewController)
		commit(delegate: storage.delegate, model: model.model)
	}
}

// MARK: UICollectionView
public protocol CollectionViewDelegate {
	func model(in collectionView: UICollectionView, on indexPath: IndexPath, at pointInCell: CGPoint) -> Model?
}

public protocol CompatibleContextMenuCollectionView {
	var contextMenuDelegate: CollectionViewDelegate { get }
}

// MARK: - Storage -

internal final class Storage<T> {
	// FIXME: retain cycle
	let delegate: T
	let context: UIViewControllerPreviewing
	var model: IndexedViewCellModel? = nil
	init(delegate: T, context: UIViewControllerPreviewing) {
		self.delegate = delegate
		self.context = context
	}
}
