#import <Preferences/Preferences.h>

#define kName @"GlowBadge"
#import <Custom/defines.h>

@interface GlowBadgeListController: PSListController {
}
- (void)openTwitter;
- (void)openDonate;
- (void)openWebsite;
@end

@implementation GlowBadgeListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"GlowBadge" target:self] retain];
	}
	return _specifiers;
}
- (void)openTwitter {
	url(@"http://twitter.com/Sassoty");
}
- (void)openDonate {
	url(@"http://bit.ly/sassotypp");
}
- (void)openWebsite {
	url(@"http://sassoty.com");
}
@end

// vim:ft=objc
