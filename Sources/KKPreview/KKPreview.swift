import UIKit

// MARK: - Model -
@objcMembers
final public class KKPreviewModel: NSObject {
	public let previewingViewController: UIViewController
	
	public let originatedFrom: CGRect?
	@available(swift, obsoleted: 1)
	public var originate: CGRect { originatedFrom ?? .null }
	
	public let actions: [KKPreviewAction]
	public let commit: KKPreviewCommit
	
	public init(previewingViewController: UIViewController, originatedFrom: CGRect? = nil, actions: [KKPreviewAction] = [], commit: KKPreviewCommit) {
		self.previewingViewController = previewingViewController
		self.originatedFrom = originatedFrom
		self.actions = actions
		self.commit = commit
		super.init()
	}

	@available(swift, obsoleted: 1)
	public convenience init(previewingViewController: UIViewController, originatedFrom: CGRect = .null, actions: [KKPreviewAction] = [], commit: KKPreviewCommit) {
		self.init(previewingViewController: previewingViewController, originatedFrom: originatedFrom == .null ? nil : originatedFrom, actions: actions, commit: commit)
	}
}

@objcMembers
final public class KKPreviewAction: NSObject {
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

@objcMembers
final public class KKPreviewCommit: NSObject {
	public typealias Handler = (UIViewController) -> Void
	let handler: Handler?
	
	@objc public enum KKPreviewCommitStyle: UInt {
		case show, showDetail, custom
	}
	public let style: KKPreviewCommitStyle
	
	init(style: KKPreviewCommitStyle, handler: Handler? = nil) {
		self.style = style
		self.handler = handler
		super.init()
	}
}

@objc extension KKPreviewCommit {
	public static let show = KKPreviewCommit(style: .show)
	public static let showDetail = KKPreviewCommit(style: .showDetail)
	public static func custom(_ handler: @escaping Handler) -> Self { .init(style: .custom, handler: handler) }
}

public struct IndexedViewCellModel {
	let model: KKPreviewModel
	let indexPath: IndexPath
	let pointInCell: CGPoint
}

// MARK: Bridge
public extension UIPreviewAction {
	convenience init(_ action: KKPreviewAction) {
		self.init(title: action.title, style: action.destructive ? .destructive : .default) { _, _ in action.handler() }
	}
}

@available(iOS 13, *)
public extension UIAction {
	convenience init(_ action: KKPreviewAction) {
		self.init(title: action.title, attributes: action.destructive ? [.destructive] : []) { _ in action.handler() }
	}
}

@available(iOS 13, *)
public extension UIMenu {
	convenience init(actions: [KKPreviewAction]) {
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

// MARK: - Compatible Protocols -
// MARK: - UIView
public protocol ViewDelegate {
	func model(in view: UIView, at point: CGPoint) -> KKPreviewModel?
}

public protocol CompatibleContextMenuView: UIView {
	func registerForCompatibleContextMenu(with delegate: ViewDelegate)
}

// MARK: - UITableView
public protocol TableViewDelegate: UIViewController {
	func model(in tableView: UITableView, on indexPath: IndexPath, at pointInCell: CGPoint) -> KKPreviewModel?
}

public extension UITableView {
	var compatibleContextMenuDelegate: TableViewDelegate? {
		get { associateValue?.delegate }
		set {
			guard compatibleContextMenuDelegate !== newValue else { return }
			
			if let storage = associateValue {
				storage.delegate.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeInteraction(UIContextMenuInteraction(delegate: self))
				}
			}
			
			guard let newValue = newValue else {
				return associateValue = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			associateValue = Storage(delegate: newValue, context: context)
		}
	}
}

// MARK: UICollectionView
public protocol CollectionViewDelegate: UIViewController {
	func model(in collectionView: UICollectionView, on indexPath: IndexPath, at pointInCell: CGPoint) -> KKPreviewModel?
}

public extension UICollectionView {
	var compatibleContextMenuDelegate: CollectionViewDelegate? {
		get { associateValue?.delegate }
		set {
			guard compatibleContextMenuDelegate !== newValue else { return }
			
			if let storage = associateValue {
				storage.delegate.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeInteraction(UIContextMenuInteraction(delegate: self))
				}
			}
			
			guard let newValue = newValue else {
				return associateValue = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			associateValue = Storage(delegate: newValue, context: context)
		}
	}
}

// MARK: - Storage -
public final class Storage<T> {
	// FIXME: retain cycle
	let delegate: T
	let context: UIViewControllerPreviewing
	var model: IndexedViewCellModel? = nil
	init(delegate: T, context: UIViewControllerPreviewing) {
		self.delegate = delegate
		self.context = context
	}
}

import SingleObjectAssociatable
extension SingleObjectAssociatable {
	public static var associatePolicy: objc_AssociationPolicy { .OBJC_ASSOCIATION_RETAIN }
}

extension UICollectionView: SingleObjectAssociatable {
	public typealias AssociateType = Storage<CollectionViewDelegate>
	public static var associateKey: StaticString = "storage"
}

extension UITableView: SingleObjectAssociatable {
	public typealias AssociateType = Storage<TableViewDelegate>
	public static var associateKey: StaticString = "storage"
}
