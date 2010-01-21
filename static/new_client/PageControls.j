/*
 * PageControls.j
 * Scan Server
 *
 * Created by Brian Taylor January 2010
 * Copyright 2010, WuboNet
 */

@import <Foundation/CPObject.j>


@implementation PageControls : CPView
{
	CPButton scanButton;
	CPButton deleteButton;
	//CPButton newDocument;

	int selectedPage;
	CPTextField pageNum;
	id _delegate;
	JSObject _theDoc;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

- (void)buildPageControlsFor:(JSObject)aDoc withSelection:(int)anIdx
{
	if(!scanButton) {
		var pcBounds = [self bounds];

		scanButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		[scanButton setTitle:@"Start Scanner"];
		[scanButton sizeToFit];
		var bBounds = [scanButton bounds];
		var buttonTop = (CGRectGetHeight(pcBounds) - CGRectGetHeight(bBounds)) / 2.0;

		var bNextX = 10;

		deleteButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		[deleteButton setTitle:@"Remove Page"];
		[deleteButton sizeToFit];
		[deleteButton setFrameOrigin: CGPointMake(bNextX, buttonTop)];
		[deleteButton setTarget:self];
		[deleteButton setAction:@selector(remove:)];
		[deleteButton setAutoresizingMask:CPViewMaxXMargin];
		bNextX += CGRectGetWidth([deleteButton bounds]) + 10;

		pageNum = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
		[pageNum setStringValue:@"Page 1"];
		[pageNum setFont:[CPFont boldSystemFontOfSize:16.0]];
		[pageNum setTextColor:[CPColor whiteColor]];
		[pageNum sizeToFit];
		[pageNum setCenter: [self center]];
		[pageNum setAutoresizingMask:CPViewMinXMargin|CPViewMaxXMargin];

		// reset to right side
		var bNextX = CGRectGetWidth(pcBounds) - 20;
		[scanButton setFrameOrigin:CGPointMake(bNextX-CGRectGetWidth(bBounds), buttonTop)];
		[scanButton setTarget:self];
		[scanButton setAction:@selector(scan:)];
		[scanButton setAutoresizingMask:CPViewMinXMargin];
		bNextX -= CGRectGetWidth(bBounds) + 10;

		/*
		newDocument = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		[newDocument setStringValue:@"Create Document"];
		[newDocument sizeToFit];
		[newDocument setFrameOrigin:CGPointMake(bNextX-CGRectGetWidth([newDocument bounds]), buttonTop)];
		[newDocument setAutoresizingMask:CPViewMinXMargin];
		bNextX -= CGRectGetWidth([newDocument bounds]) + 10;
		*/
	}

	_theDoc = aDoc;
	if(_theDoc) {
		[self addSubview:scanButton];
		//[self addSubview:newDocument];
	} else {
		[scanButton removeFromSuperview];
		//[newDocument removeFromSuperview];
	}

	if(anIdx == -1) {
		[deleteButton removeFromSuperview];
		[pageNum removeFromSuperview];
	} else {
		selectedPage = anIdx;
		var modPageNum = anIdx + 1;
		[pageNum setStringValue:[CPString stringWithFormat:@"Page %d", modPageNum]];
		[self addSubview:deleteButton];
		[self addSubview:pageNum];
	}
}

- (void)scan:(id)sender
{
	[_delegate scanForDocument:_theDoc];
}

- (void)remove:(id)sender
{
	[_delegate remove:selectedPage];
}

- (void)move:(id)sender
{
	alert("dis donna work jis yet");
}

@end

