import func ObjectiveC.runtime.objc_getAssociatedObject
import func ObjectiveC.runtime.objc_setAssociatedObject
import enum ObjectiveC.runtime.objc_AssociationPolicy

public protocol SingleObjectAssociatable: AnyObject {
	associatedtype AssociateType
	static var associatePolicy: objc_AssociationPolicy { get }
	var associateValue: AssociateType? { get set }
}

private var associateKey: StaticString = "SingleObjectAssociatableKey"
public extension SingleObjectAssociatable {
	var associateValue: AssociateType? {
		get { objc_getAssociatedObject(self, &associateKey) as? AssociateType }
		set { objc_setAssociatedObject(self, &associateKey, newValue, Self.associatePolicy) }
	}
}
