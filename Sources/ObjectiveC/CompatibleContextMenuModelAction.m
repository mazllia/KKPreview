#import "CompatibleContextMenuModelAction.h"

@implementation CompatibleContextMenuModelAction
- (instancetype)init {
	NSAssert(NO, @"Use desginated initializer instead.");
	return [self initWithTitle:@"" handler:^{}];
}

- (instancetype)initWithTitle:(NSString *)title destructive:(BOOL)destructive handler:(CompatibleContextMenuModelActionHandler)handler {
	self = [super init];
	if (self) {
		_title = title;
		_destructive = destructive;
		_handler = handler;
	}
	return self;
}

- (instancetype)initWithTitle:(NSString *)title handler:(CompatibleContextMenuModelActionHandler)handler {
	return [self initWithTitle:title destructive:NO handler:handler];
}
@end
