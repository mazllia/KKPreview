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
