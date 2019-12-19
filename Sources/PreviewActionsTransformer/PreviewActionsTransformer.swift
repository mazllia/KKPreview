import Foundation

@objcMembers @available(swift, obsoleted: 1)
public final class PreviewActionsTransformer: NSObject {
	public static func toUIPreviewActions(_ actions: [KKPreviewAction]) -> [UIPreviewAction] {
		actions.map { .init($0) }
	}
	
	@available(iOS 13, *)
	@objc public static func toUIActions(_ actions: [KKPreviewAction]) -> [UIAction] {
		actions.map { .init($0) }
	}
}
