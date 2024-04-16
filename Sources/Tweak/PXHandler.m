#import "PXHandler.h"

@interface PXHandler ()
@property NSMutableArray<NSNumber *> *recentHistory; // Used to store current sequence triggered
@property NSDate *cooldown; // Used for handling our sequence trigger cooldowns (1 second)
@property BOOL shouldRemoveLastValueOnSingle;
@end

@implementation PXHandler
+ (instancetype)globalHandler {
	static PXHandler *handler = nil;
	static dispatch_once_t once_token;

	dispatch_once(&once_token, ^{
		handler = [[self alloc] init];
		handler.cooldown = [NSDate date];
		handler.recentHistory = [NSMutableArray new];
		handler.shouldRemoveLastValueOnSingle = NO;
	});

	return handler;
}

- (void)handlePressesFrom:(UIPressesEvent *)event {
	// Cooldown checks (we have a 1 second cooldown)
	NSTimeInterval interval = [self.cooldown timeIntervalSinceNow];
	self.cooldown = [NSDate date];

	// Negative because intervals are a difference
	if (interval < -1) [self.recentHistory removeAllObjects];

	// The event emitter will give us 105 as a button type which represents haptic home button
	// While we are here we can also filter out events where the button isn't actually pressed down
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIPress *press, NSDictionary *bindings) {
		if (press.type == 105) {
			return NO;
		}

		if (press.force != 1) {
			return NO;
		}

		return YES;
	}];

	NSArray *presses = [[event.allPresses.allObjects mutableCopy] filteredArrayUsingPredicate:predicate];

	// 101 -> Home Button
	// 102 -> Volume Up
	// 103 -> Volume Down
	// 104 -> Power Button

	// Single Buttons
	if (presses.count == 1) {
		UIPress *press = presses[0];

		[self.recentHistory addObject:@(press.type)];
		if (self.shouldRemoveLastValueOnSingle) {
			[self.recentHistory removeLastObject];
			self.shouldRemoveLastValueOnSingle = NO;
		};
	}

	// 205 -> Volume Up + Volume Down
	// 207 -> Home Button + Volume Up
	// 208 -> Home Button + Volume Down
	// 209 -> Home Button + Power Button

	// For these, we sum the types and forces together
	if (presses.count == 2) {
		UIPress *firstPress = event.allPresses.allObjects[0];
		UIPress *secondPress = event.allPresses.allObjects[1];

		[self.recentHistory removeLastObject];
		[self.recentHistory addObject:@(firstPress.type + secondPress.type)];
		self.shouldRemoveLastValueOnSingle = YES;
	}

	// This is delayed 50ms so that there's time for us to modify recentHistory on double button presses
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
		[self commitActions];
	});
}

- (void)commitActions {
	// Yikes, because NSCountedSet reorders an NSArray, I have to convert the arrays to strings
	NSString *recentPattern = [self.recentHistory componentsJoinedByString:@"."];
	NSLog(@"[Panic] Current Pattern: %@", recentPattern);

	if ([recentPattern isEqualToString:self.respringSequence]) {
		[self respringDevice];
		return;
	}

	if ([recentPattern isEqualToString:self.safemodeSequence]) {
		[self safemodeDevice];
		return;
	}
}

- (void)respringDevice {
	if (self.respringEnabled) {
		pid_t pid;

		// Check to see if 'sbreload' exists, otherwise just respring via 'killall'
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb/usr/bin/sbreload"]) {
			const char* args[] = {"sbreload", NULL};
			posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
		} else {
			const char* args[] = {"killall", "SpringBoard", NULL};
			posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
		}
	}
}

- (void)safemodeDevice {
	if (self.safemodeEnabled) {
		pid_t pid;
		const char* args[] = {"killall", "-SEGV", "SpringBoard", NULL};
		posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	}
}

@end
