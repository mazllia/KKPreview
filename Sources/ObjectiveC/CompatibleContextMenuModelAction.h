@import Foundation;

NS_SWIFT_NAME(Action)
@interface CompatibleContextMenuModelAction : NSObject
typedef void (^CompatibleContextMenuModelActionHandler)(void);
NS_ASSUME_NONNULL_BEGIN
@property (readonly) NSString *title;
@property (readonly) BOOL destructive;
@property (readonly) CompatibleContextMenuModelActionHandler handler;

/// This initializer returns invalid instance and @c assertionFailure().
- (instancetype)init NS_UNAVAILABLE NS_REFINED_FOR_SWIFT;
- (instancetype)initWithTitle:(NSString *)title destructive:(BOOL)destructive handler:(CompatibleContextMenuModelActionHandler)handler NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;
- (instancetype)initWithTitle:(NSString *)title handler:(CompatibleContextMenuModelActionHandler)handler NS_REFINED_FOR_SWIFT;
NS_ASSUME_NONNULL_END
@end
