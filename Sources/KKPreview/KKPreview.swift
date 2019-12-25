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

final class PointedModel {
	let model: KKPreviewModel
	let point: CGPoint
	init(model: KKPreviewModel, point: CGPoint) {
		self.model = model
		self.point = point
	}
}

// MARK: Bridge
@objc public extension UIPreviewAction {
	convenience init(_ action: KKPreviewAction) {
		self.init(title: action.title, style: action.destructive ? .destructive : .default) { _, _ in action.handler() }
	}
}

@available(iOS 13, *)
@objc public extension UIAction {
	convenience init(_ action: KKPreviewAction) {
		self.init(title: action.title, attributes: action.destructive ? [.destructive] : []) { _ in action.handler() }
	}
}

@available(iOS 13, *)
@objc public extension UIMenu {
	convenience init(actions: [KKPreviewAction]) {
		self.init(title: "", children: actions.map { UIAction($0) })
	}
}

// MARK: - Protocol -
@objc public protocol ViewDelegate {
	func view(_ view: UIView, modelAt point: CGPoint) -> KKPreviewModel?
}

@objc public protocol IndexedViewDelegate {
	@objc optional func view(_ view: UIView, modelAt point: CGPoint) -> KKPreviewModel?
	func indexedView(_ indexedView: UIView, modelOn indexPath: IndexPath, at pointInCell: CGPoint) -> KKPreviewModel?
}

public typealias PreviewDelegate = UIViewController & ViewDelegate
public typealias IndexedPreviewDelegate = UIViewController & IndexedViewDelegate

// MARK: - Delegate Property -
@objc public extension UIView {
	/// Unable to find the `UIContextMenuInteraction` instance previously registered because storing such iOS 13+ available instance in `Storage` would also make `Storage` iOS 13+ available, making implementation difficult.
	@available(iOS 13.0, *)
	func removeUIContextMenuInteractionDelegatesTo(_ delegate: UIContextMenuInteractionDelegate) {
		interactions
			.compactMap { $0 as? UIContextMenuInteraction }
			.filter { $0.delegate === delegate }
			.forEach { removeInteraction($0) }
	}
	
	var previewDelegate: PreviewDelegate? {
		get { viewStorage?.delegate }
		set {
			guard previewDelegate !== newValue else { return }
			
			if let storage = storage as? RegisterStorage {
				storage.viewController?.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeUIContextMenuInteractionDelegatesTo(self)
				}
			}
			
			guard let newValue = newValue else {
				return viewStorage = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			viewStorage = .init(delegate: newValue, context: context)
		}
	}
}

@objc public extension UITableView {
	var indexedPreviewDelegate: IndexedPreviewDelegate? {
		get { indexViewStorage?.delegate }
		set {
			guard indexedPreviewDelegate !== newValue else { return }
			
			if let storage = storage as? RegisterStorage {
				storage.viewController?.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeUIContextMenuInteractionDelegatesTo(self)
				}
			}
			
			guard let newValue = newValue else {
				return indexViewStorage = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			indexViewStorage = .init(delegate: newValue, context: context)
		}
	}
}

@objc public extension UICollectionView {
	var indexedPreviewDelegate: IndexedPreviewDelegate? {
		get { indexViewStorage?.delegate }
		set {
			guard indexedPreviewDelegate !== newValue else { return }
			
			if let storage = storage as? RegisterStorage {
				storage.viewController?.unregisterForPreviewing(withContext: storage.context)
				if #available(iOS 13.0, *) {
					removeUIContextMenuInteractionDelegatesTo(self)
				}
			}
			
			guard let newValue = newValue else {
				return indexViewStorage = nil
			}
			let context = newValue.registerForPreviewing(with: self, sourceView: self)
			if #available(iOS 13.0, *) {
				addInteraction(UIContextMenuInteraction(delegate: self))
			}
			indexViewStorage = .init(delegate: newValue, context: context)
		}
	}
}

private protocol RegisterStorage {
	var viewController: UIViewController? { get }
	var context: UIViewControllerPreviewing { get }
}

extension Storage: RegisterStorage {
	var viewController: UIViewController? { delegate }
}

// MARK: - Storage -
final class Storage<T: UIViewController> {
	let context: UIViewControllerPreviewing
	var model: PointedModel? = nil
	
	weak var delegate: T?
	init(delegate: T, context: UIViewControllerPreviewing) {
		self.delegate = delegate
		self.context = context
	}
}

/// Shared key to override `viewStorage` & `indexViewStorage`
private var associateKey: StaticString = "KKPreviewStorageAssociataingKey"

typealias ViewStorage = Storage<PreviewDelegate>
typealias IndexViewStorage = Storage<IndexedPreviewDelegate>

extension UIView {
	var storage: Any? {
		get { objc_getAssociatedObject(self, &associateKey) }
		set { objc_setAssociatedObject(self, &associateKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
	}
	
	var viewStorage: ViewStorage? {
		get { storage as? ViewStorage }
		set { storage = newValue }
	}
}

extension UITableView {
	var indexViewStorage: IndexViewStorage? {
		get { storage as? IndexViewStorage }
		set { storage = newValue }
	}
}

extension UICollectionView {
	var indexViewStorage: IndexViewStorage? {
		get { storage as? IndexViewStorage }
		set { storage = newValue }
	}
}

// MARK: - UIViewController Presentation -
@available(iOS 13, *)
@objc public extension UITargetedPreview {
	@objc convenience init(view: UIView, rounded rect: CGRect, cornerRadius: CGFloat = 3) {
		let parameters = UIPreviewParameters()
		parameters.visiblePath = .init(roundedRect: rect, cornerRadius: cornerRadius)
		parameters.backgroundColor = .clear
		
		self.init(view: view, parameters: parameters)
	}
}

protocol InteractivePreviewStorage: AnyObject {
	var presentingViewController: UIViewController? { get }
	var model: PointedModel? { get set }
}

extension Storage: InteractivePreviewStorage {
	var presentingViewController: UIViewController? { delegate }
}

@objc public extension UIViewController {
	func commit(_ model: KKPreviewModel) {
		let viewController = model.previewingViewController
		switch model.commit.style {
		case .show: show(viewController, sender: self)
		case .showDetail: showDetailViewController(viewController, sender: self)
		case .custom: model.commit.handler?(viewController)
		}
	}
}

// MARK: Point -> Cell
public extension UITableView {
	/// - parameter location: location in table view
	/// - returns: point in cell and index path of such cell
	func convert(_ location: CGPoint) -> (cell: UIView, indexPath: IndexPath, location: CGPoint)? {
		guard
			let indexPath = indexPathForRow(at: location),
			let cell = cellForRow(at: indexPath) else { return nil }
		return (cell, indexPath, convert(location, to: cell))
	}
}

public extension UICollectionView {
	/// - parameter location: location in table view
	/// - returns: point in cell and index path of such cell
	func convert(_ location: CGPoint) -> (cell: UIView, indexPath: IndexPath, location: CGPoint)? {
		guard
			let indexPath = indexPathForItem(at: location),
			let cell = cellForItem(at: indexPath) else { return nil }
		return (cell, indexPath, convert(location, to: cell))
	}
}
