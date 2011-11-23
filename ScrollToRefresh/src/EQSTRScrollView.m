//
//  EQSTRScrollView.m
//  ScrollToRefresh
//
// Copyright (C) 2011 by Alex Zielenski.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "EQSTRScrollView.h"
#import "EQSTRClipView.h"
#import <QuartzCore/QuartzCore.h>

#define REFRESH_HEADER_HEIGHT 60.0f

// code modeled from https://github.com/leah/PullToRefresh/blob/master/Classes/PullRefreshTableViewController.m

@implementation EQSTRScrollView
@synthesize isRefreshing, refreshHeader, target, selector, refreshSpinner, refreshArrow;
- (void)viewDidMoveToWindow {
	[self createHeaderView];
}
- (NSClipView*)contentView {
	NSClipView *superClipView = [super contentView];
	if (![superClipView isKindOfClass:[EQSTRClipView class]]) {
		// create new clipview
		NSView *documentView = superClipView.documentView;
		
		EQSTRClipView *clipView = [[EQSTRClipView alloc] initWithFrame:superClipView.frame];
		clipView.documentView=documentView;
		clipView.copiesOnScroll=NO;
		clipView.drawsBackground=NO;
		[self setContentView:clipView];
		
		[clipView release];
		
		superClipView = [super contentView];
	}
	return superClipView;
}
- (void)createHeaderView {
	// delete old stuff if any
	if (refreshHeader) {		
		[refreshHeader removeFromSuperview];
		[refreshHeader release];
		refreshHeader = nil;
	}
	
	[self setVerticalScrollElasticity:NSScrollElasticityAllowed];
	
	(void)self.contentView; // create new content view
	
	[self.contentView setPostsFrameChangedNotifications:YES];
	[self.contentView setPostsBoundsChangedNotifications:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(viewBoundsChanged:)
												 name:NSViewBoundsDidChangeNotification 
											   object:self.contentView];
	
	// add header view to clipview
	NSRect contentRect = [self.contentView.documentView frame];
	refreshHeader = [[NSView alloc] initWithFrame:NSMakeRect(0, 
															 0-REFRESH_HEADER_HEIGHT, //contentRect.origin.y+contentRect.size.height, 
															 contentRect.size.width, 
															 REFRESH_HEADER_HEIGHT)];
	
	// arrow
	NSImage *arrowImage = [NSImage imageNamed:@"arrow"];
	refreshArrow = [[NSView alloc] initWithFrame:NSMakeRect(floor(NSMidX(refreshHeader.bounds)-arrowImage.size.width/2), 
															floor(NSMidY(refreshHeader.bounds)-arrowImage.size.height/2), 
															arrowImage.size.width,
															arrowImage.size.height)];
	refreshArrow.wantsLayer=YES;
	refreshArrow.layer=[CALayer layer];
	refreshArrow.layer.contents=(id)[arrowImage CGImageForProposedRect:NULL
															   context:nil
																 hints:nil];

	refreshSpinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(floor(NSMidX(refreshHeader.bounds)-30),
																		   floor(NSMidY(refreshHeader.bounds)-20), 
																		   60.0f, 
																		   40.0f)];
	refreshSpinner.style=NSProgressIndicatorSpinningStyle;
	refreshSpinner.displayedWhenStopped=NO;
	refreshSpinner.usesThreadedAnimation=YES;
	refreshSpinner.indeterminate=YES;
	refreshSpinner.bezeled=NO;
	[refreshSpinner sizeToFit];
	
	[refreshSpinner setFrame:NSMakeRect(floor(NSMidX(refreshHeader.bounds)-refreshSpinner.frame.size.width/2),
										floor(NSMidY(refreshHeader.bounds)-refreshSpinner.frame.size.height/2), 
										refreshSpinner.frame.size.width, 
										refreshSpinner.frame.size.height)];
	
	// set autoresizing masks
	refreshSpinner.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin; // center
	refreshArrow.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin; // center
	refreshHeader.autoresizingMask = NSViewWidthSizable | NSViewMinXMargin | NSViewMaxXMargin; // stretch/center
	
	[refreshHeader addSubview:refreshArrow];
	[refreshHeader addSubview:refreshSpinner];
	
	[self.contentView addSubview:refreshHeader];	
	
	[refreshArrow release];
	[refreshSpinner release];
	
	[self.contentView scrollToPoint:NSMakePoint(contentRect.origin.x, 0)];
	[self reflectScrolledClipView:self.contentView];
}
- (void)scrollWheel:(NSEvent *)event {
	if (event.phase==NSEventPhaseEnded) {
		if (overHeaderView&&!isRefreshing) {
			[self startLoading];
		}
	}
	[super scrollWheel:event];
}
- (void)viewBoundsChanged:(NSNotification*)note {
	if (isRefreshing)
		return;
	BOOL start = [self overRefreshView];
	if (start) {
		// point arrow up
		[refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
		overHeaderView = YES;
	} else {
		// point arrow down
		[refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
		overHeaderView = NO;
	}
	
}
- (BOOL)overRefreshView {
	NSClipView *clipView = self.contentView;
	NSRect bounds = clipView.bounds;
	
	CGFloat scrollValue = bounds.origin.y;
	CGFloat minimumScroll = self.minimumScroll;
	
	return (scrollValue<=minimumScroll);
}
- (void)startLoading {
	[self willChangeValueForKey:@"isRefreshing"];
	isRefreshing = YES;
	[self didChangeValueForKey:@"isRefreshing"];
	
	refreshArrow.hidden = YES;
	[refreshSpinner startAnimation:self];
	
	if (self.target&&[self.target respondsToSelector:self.selector])
		[self.target performSelectorOnMainThread:self.selector 
									  withObject:self
								   waitUntilDone:YES];
}
- (void)stopLoading {	
	refreshArrow.hidden = NO;	
	[refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
	[refreshSpinner stopAnimation:self];
	
	// now fake an event of scrolling for a natural look
	
	[self willChangeValueForKey:@"isRefreshing"];
	isRefreshing = NO;
	[self didChangeValueForKey:@"isRefreshing"];
	
	CGEventRef cgEvent = CGEventCreateScrollWheelEvent(NULL,
													   kCGScrollEventUnitLine,
													   2,
													   1,
													   0);
	NSEvent *scrollEvent = [NSEvent eventWithCGEvent:cgEvent];
	[self scrollWheel:scrollEvent];
	CFRelease(cgEvent);
}
- (CGFloat)minimumScroll {
	return 0-refreshHeader.frame.size.height;
}
@end
