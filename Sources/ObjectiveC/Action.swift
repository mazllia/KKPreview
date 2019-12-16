@available(swift, deprecated: 1)
@objcMembers final public class Action: NSObject {
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

import CompatibleContextMenuInteraction
public extension CompatibleContextMenuInteraction.Model.Action {
	init(_ action: Action) {
		self.init(title: action.title, destructive: action.destructive, handler: action.handler)
	}
}
