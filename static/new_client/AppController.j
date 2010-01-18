/*
 * AppController.j
 * NewApplication
 *
 * Created by You on July 5, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
	CPDictionary photosets;
	CPCollectionView leftCollection;

	CPView rightView;
	CPCollectionView rightCollection;

	CPView pageControls;
}

- (void)buildPageControls {
	var rvBounds = [rightView bounds],
	    bottom = CGRectGetHeight(rvBounds);

	pageControls = [[CPView alloc] initWithFrame:CGRectMake(0,bottom-54,CGRectGetWidth(rvBounds), 54)];
	[pageControls setBackgroundColor: [CPColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[pageControls setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];

	var pcBounds = [pageControls bounds];

	var scanButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
	//CGRectMake(CGRectGetWidth(pcBounds)-100,10,90,CGRectGetHeight(pcBounds)-20)];
	[scanButton setTitle:@"Scan Page"];
	[scanButton sizeToFit];
	var bBounds = [scanButton bounds];
	var buttonTop = (CGRectGetHeight(pcBounds) - CGRectGetHeight(bBounds)) / 2.0;
	var bNextX = 10;

	[scanButton setFrameOrigin: CGPointMake(bNextX, buttonTop)];
	[pageControls addSubview:scanButton];
	bNextX += CGRectGetWidth([scanButton bounds]) + 10;

	var deleteButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
	[deleteButton setTitle:@"Delete Page"];
	[deleteButton sizeToFit];
	[deleteButton setFrameOrigin: CGPointMake(bNextX, buttonTop)];
	[pageControls addSubview:deleteButton];
	bNextX += CGRectGetWidth([deleteButton bounds]) + 10;

	[rightView addSubview:pageControls];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

	photosets = [CPDictionary dictionary];

	var cvBounds = [contentView bounds],
	    splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0,0, CGRectGetWidth(cvBounds), CGRectGetHeight(cvBounds))];

	[splitView setDelegate:self];
	[splitView setVertical: YES];
	[splitView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
	[contentView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];

	var svBounds = [splitView bounds];

	// build the right pane
	rightView = [[CPView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(svBounds)-200, CGRectGetHeight(svBounds))];
	[rightView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
	[rightView setBackgroundColor: [CPColor colorWithRed:213.0/255 green:221.0/255.0 blue:230.0/255.0 alpha:1.0]];

	var rvBounds = [rightView bounds];
	
	var rightScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rvBounds),CGRectGetHeight(rvBounds)-54)],
	    rsvBounds = [rightScrollView bounds];

	[rightScrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable|CPViewMinYMargin ];
	[rightScrollView setAutohidesScrollers:YES];
	
	rightCollection = [[CPCollectionView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rsvBounds),0)];
	[rightCollection setDelegate:self];
	var rcItemSz = CGSizeMake(CGRectGetWidth(rsvBounds), CGRectGetHeight(rsvBounds));
	[rightCollection setMinItemSize:rcItemSz];
	[rightCollection setMaxItemSize:rcItemSz];
	[rightCollection setMaxNumberOfColumns:1];
	[rightCollection setVerticalMargin:0.0];
	[rightCollection setAutoresizingMask:CPViewWidthSizable];

	var pageItem = [[CPCollectionViewItem alloc] init];
	[pageItem setView:[[PageCell alloc] initWithFrame:CGRectMakeZero()]];
	[rightCollection setItemPrototype:pageItem];

	[rightScrollView setDocumentView:rightCollection];
	[rightView addSubview:rightScrollView];

	// build the left pane
	var leftScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0,0,200, CGRectGetHeight(svBounds))],
		lsvBounds = [leftScrollView bounds];
	[leftScrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable ];
	[leftScrollView setAutohidesScrollers:YES];

	leftCollection = [[CPCollectionView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(lsvBounds), 0)];

	[leftCollection setDelegate:self];
	[leftCollection setMinItemSize:CGSizeMake(20.0, 45.0)];
	[leftCollection setMaxItemSize:CGSizeMake(1000.0, 45.0)];
	[leftCollection setMaxNumberOfColumns:1];
	[leftCollection setVerticalMargin:0.0];
	[leftCollection setAutoresizingMask:CPViewWidthSizable ];

	var photoItem = [[CPCollectionViewItem alloc] init];
	[photoItem setView:[[DocumentCell alloc] initWithFrame:CGRectMake(0,0,150,150)]];
	[leftCollection setItemPrototype:photoItem];
	[leftScrollView setDocumentView:leftCollection];

	[self buildPageControls];
	// fill in some test data
	/*
	[photosets setObject:@"test" forKey:@"test"];
	[photosets setObject:@"test" forKey:@"test2"];
	[photosets setObject:@"test" forKey:@"test3"];
	[leftCollection setContent:[[photosets allKeys] copy]];
	*/

	//[[leftScrollView contentView] setBackgroundColor:[CPColor blackColor]];

	[splitView addSubview:leftScrollView];
	[splitView addSubview:rightView];

	/*
    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"Hello World!"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[rightView center]];

    [rightView addSubview:label];
	*/

	[contentView addSubview:splitView];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];

	// fetch the document data
	var request = [CPURLRequest requestWithURL:"http://localhost:8000/documents?format=json"];
	var connection = [CPJSONPConnection sendRequest:request callback:"jsoncallback" delegate:self];
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
	if(aCollectionView == leftCollection) {
		var idx = [[leftCollection selectionIndexes] firstIndex],
		    key = [leftCollection content][idx],
			record = [photosets objectForKey:key];

		[rightCollection setContent:[[CPArray alloc] initWithArray:record.pages]];
	}
}

- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(CPString)data
{
	for (var i = 0; i < data.length; i++) {
		[photosets setObject:data[i] forKey:data[i].name]
	}
	[leftCollection setContent:[[photosets allKeys] copy]];
}

- (void)connection:(CPJSONPConnection)aConnection didFailWithError:(CPString)error
{
	alert("error: "  + error);
}

@end

@implementation DocumentCell : CPView
{
	CPTextField textField;
	CPView highlightView;
}

- (void)setRepresentedObject:(JSObject)anObject
{
	if(!textField) {
		textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
		[textField setFont:[CPFont systemFontOfSize:12.0]];
		[textField setAutoresizingMask: CPViewMinXMargin|CPViewMaxXMargin|CPViewMinYMargin|CPViewMaxYMargin];
		[textField setTextColor:[CPColor blackColor]];
		[textField setTextShadowColor:[CPColor whiteColor]];
		[textField setTextShadowOffset:CGSizeMake(1,1)];
		[self addSubview:textField];
	}

	[textField setStringValue:anObject];
	[textField sizeToFit];
	[textField setCenter:[self center]];
}

- (void)setSelected:(BOOL)flag
{
	if(!highlightView) {
		highlightView = [[CPView alloc] initWithFrame:[self bounds]];
		[highlightView setBackgroundColor:[CPColor grayColor]];
		[highlightView setAutoresizingMask:CPViewWidthSizable];
	}

	if(flag) {
		[self addSubview:highlightView positioned:CPWindowBelow relativeTo:textField];
	} else {
		[highlightView removeFromSuperview];
	}
}

@end

@implementation DataModel : CPObject
{
	CPDictionary data;
}

@end

@implementation PageCell : CPView
{
	CPImageView imageView;
	CPImage image;
}

- (void)setRepresentedObject:(JSObject)anObject
{
	if(!imageView) {
		//alert(CGRectGetWidth([self bounds]) + ", " + CGRectGetHeight([self bounds]));
		imageView = [[CPImageView alloc] initWithFrame: [self bounds]];
		[imageView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[imageView setImageScaling:CPScaleProportionally];
		[imageView setHasShadow:YES];
		[self addSubview:imageView];
	}

	var pickey = anObject.key;
	var picfile = "http://localhost:8000/thumbnail/" + pickey + "?format=pagesized";
	var pgImage = [[CPImage alloc] initWithContentsOfFile:picfile];

	if([pgImage loadStatus] == CPImageLoadStatusCompleted) {
		[imageView setImage: pgImage];
		[pgImage setDelegate:nil];
	} else {
		[pgImage setDelegate:self];
	}
}

- (void)setSelected:(BOOL)flag
{
	// ignore for now
}

- (void)imageDidLoad:(CPImage)anImage
{
	[imageView setImage:anImage];
}

@end
