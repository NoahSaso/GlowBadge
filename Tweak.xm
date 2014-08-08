#import <QuartzCore/QuartzCore.h>
#import "UIImage-DominantColor/UIImage+DominantColor.h"

#define kName @"GlowBadge"
#import <Custom/defines.h>

#include <stdlib.h>

#define kHideBadges 0
#define kOnlyFolders 1
#define kListApps 2
#define kShowBadges 3

@interface SBIcon : NSObject
- (id)badgeNumberOrString;
- (id)displayName;
- (id)getIconImage:(int)arg1;
- (BOOL)isFolderIcon;
@end

@interface SBIconView : UIView
@property (retain, nonatomic) SBIcon *icon;
- (CGFloat)calculateRadius;
- (BOOL)hasBadge;
@end

#define kSettingsPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.glowbadge.plist"]
NSDictionary* prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
BOOL isEnabled = YES;
int showBadge = kShowBadges;
NSArray* badgeWhitelist = [[NSArray alloc] init];

UIColor* daColor;
BOOL sameAsApp = NO;

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

	if(color != 673 && color != 674) {
		sameAsApp = NO;
		daColor = colors[color];
	}else if(color == 673) {
		sameAsApp = NO;
		//Pick random color
		int r = arc4random_uniform([colors count]);
		while(r == 2) {
			r = arc4random_uniform([colors count]);
		}
		daColor = colors[r];
	}else if(color == 674){
		sameAsApp = YES;
	}else {
		sameAsApp = NO;
		daColor = [UIColor yellowColor];
	}
}

void reloadPrefs() {
	prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	
	isEnabled = [prefs[@"Enabled"] boolValue];
	if(!prefs[@"Enabled"]) { isEnabled = YES; }

	showBadge = [prefs[@"ShowBadges"] intValue];
	if(!prefs[@"ShowBadges"]) { showBadge = kShowBadges; }

	badgeWhitelist = prefs[@"BadgeWhitelist"];
	if(!badgeWhitelist) { badgeWhitelist = [[NSArray alloc] init]; }

	checkColor();
}

@interface SBIconBadgeView : UIView
@end

%hook SBIconBadgeView

- (void)layoutSubviews {
	%orig;
	if(!isEnabled) {
		self.hidden = NO;
	}
	SBIconView* iconView = (SBIconView *)[self superview];
	switch(showBadge) {
		case kHideBadges:
			self.hidden = YES;
			break;
		case kOnlyFolders: {
			if([iconView.icon isFolderIcon]) {
				self.hidden = NO;
			}else {
				self.hidden = YES;
			}
			break;
		}
		case kListApps: {
			if([badgeWhitelist containsObject:[iconView.icon displayName]]) {
				self.hidden = NO;
			}else {
				self.hidden = YES;
			}
			break;
		}
		case kShowBadges:
			self.hidden = NO;
			break;
		default:
			self.hidden = NO;
			break;
	}
}

%end

%hook SBIconView

- (void)layoutSubviews {
	%orig;
	if(isEnabled && [self hasBadge]) {
		if(!daColor && !sameAsApp) {
			reloadPrefs();
		}

		CGFloat daFloat = [self calculateRadius];
		if(daFloat <= 4.0f) {
			return;
		}
		if(daFloat > 17.5f) {
			daFloat = 17.5f;
		}

		if(!sameAsApp) {
			checkColor();
		}else {
			daColor = [(UIImage *)[self.icon getIconImage:2] dominantColor];
		}

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
		returnFloat += 6.0f;

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
