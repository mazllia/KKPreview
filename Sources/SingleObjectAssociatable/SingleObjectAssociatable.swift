import func ObjectiveC.runtime.objc_getAssociatedObject
import func ObjectiveC.runtime.objc_setAssociatedObject
import enum ObjectiveC.runtime.objc_AssociationPolicy

public protocol SingleObjectAssociatable: AnyObject {
	associatedtype AssociateType
	static var associatePolicy: objc_AssociationPolicy { get }
	static var associateKey: StaticString { get set }
	var associateValue: AssociateType? { get set }
}

public extension SingleObjectAssociatable {
	var associateValue: AssociateType? {
		get { objc_getAssociatedObject(self, &Self.associateKey) as? AssociateType }
		set { objc_setAssociatedObject(self, &Self.associateKey, newValue, Self.associatePolicy) }
	}
}
