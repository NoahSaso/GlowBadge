#import <QuartzCore/QuartzCore.h>

#define kName @"GlowBadge"
#import <Custom/defines.h>

#include <stdlib.h>

@interface SBIcon : NSObject
- (id)badgeNumberOrString;
- (id)displayName;
@end

@interface SBIconView : UIView
@property (retain, nonatomic) SBIcon *icon;
- (CGFloat)calculateRadius;
- (BOOL)hasBadge;
@end

#define kSettingsPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.glowbadge.plist"]
NSDictionary* prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
BOOL isEnabled = YES;
BOOL hideBadge = NO;

UIColor* daColor;

NSArray* colors = [[NSArray alloc] initWithObjects:
	[UIColor yellowColor],
	[UIColor darkGrayColor],
	[UIColor lightGrayColor],
	[UIColor grayColor],
	[UIColor redColor],
	[UIColor greenColor],
	[UIColor blueColor],
	[UIColor cyanColor],
	[UIColor magentaColor],
	[UIColor orangeColor],
	[UIColor purpleColor],
	[UIColor brownColor],
	[UIColor blackColor],
	nil
	];

void checkColor() {
	int color = [prefs[@"Color"] intValue];
	if(!prefs[@"Color"]) { color = 0; }

	if(color != 673) {
		daColor = colors[color];
	}else {
		//Pick random color
		int r = arc4random_uniform([colors count]);
		while(r == 2) {
			r = arc4random_uniform([colors count]);
		}
		daColor = colors[r];
	}
}

void reloadPrefs() {
	prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	
	isEnabled = [prefs[@"Enabled"] boolValue];
	if(!prefs[@"Enabled"]) { isEnabled = YES; }
	hideBadge = [prefs[@"HideBadge"] boolValue];
	if(!prefs[@"HideBadge"]) { hideBadge = NO; }

	checkColor();
}

@interface SBIconBadgeView : UIView
@end

%hook SBIconBadgeView

- (void)layoutSubviews {
	%orig;
	if(isEnabled && hideBadge) {
		self.alpha = 0.0;
	}else {
		self.alpha = 1.0;
	}
}

%end

%hook SBIconView

- (void)layoutSubviews {
	%orig;
	if(isEnabled && [self hasBadge]) {
		if(!daColor) {
			reloadPrefs();
		}
		CGFloat daFloat = [self calculateRadius];
		if(daFloat <= 4.0f) {
			return;
		}
		if(daFloat > 15.0f) {
			daFloat = 15.0f;
		}
		checkColor();
		self.layer.shadowColor = [daColor CGColor];
		self.layer.shadowRadius = daFloat;
		self.layer.shadowOpacity = 1.0;
		self.layer.shadowOffset = CGSizeZero;
		self.layer.masksToBounds = NO;
	}else {
		self.layer.shadowColor = [[UIColor clearColor] CGColor];
		self.layer.shadowRadius = 0.0f;
		self.layer.shadowOpacity = 0.0;
	}
}

%new
- (BOOL)hasBadge {
	id badge = [self.icon badgeNumberOrString];

	if([badge isKindOfClass:[NSNumber class]]) {
		return YES;
	}else {
		return NO;
	}
}

%new
- (CGFloat)calculateRadius {

	id badge = [self.icon badgeNumberOrString];

	if([badge isKindOfClass:[NSNumber class]]) {

		CGFloat returnFloat = (CGFloat) [badge floatValue] * 2.0f;
		returnFloat += 4.0f;

		return returnFloat;

	}

	return 0.0f;

}

%end

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)reloadPrefs,
        CFSTR("com.sassoty.glowbadge/preferencechanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}
