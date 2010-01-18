/*
 * AppController.j
 * NewApplication
 *
 * Created by You on July 5, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation PageControls : CPView
{
	CPButton scanButton;
	CPButton deleteButton;

	CPIndexSet selectedPages;
	CPTextField pageNum;
	id _delegate;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

- (void)buildPageControlsFor:(CPIndexSet)aIndexSet
{
	if(!scanButton) {
		var pcBounds = [self bounds];
		scanButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		//CGRectMake(CGRectGetWidth(pcBounds)-100,10,90,CGRectGetHeight(pcBounds)-20)];
		[scanButton setTitle:@"Scan Page"];
		[scanButton sizeToFit];
		var bBounds = [scanButton bounds];
		var buttonTop = (CGRectGetHeight(pcBounds) - CGRectGetHeight(bBounds)) / 2.0;
		var bNextX = 10;

		[scanButton setFrameOrigin: CGPointMake(bNextX, buttonTop)];
		[scanButton setTarget:self];
		[scanButton setAction:@selector(scan:)];

		bNextX += CGRectGetWidth([scanButton bounds]) + 10;

		deleteButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		[deleteButton setTitle:@"Remove Page"];
		[deleteButton sizeToFit];
		[deleteButton setFrameOrigin: CGPointMake(bNextX, buttonTop)];
		[deleteButton setTarget:self];
		[deleteButton setAction:@selector(remove:)];
		bNextX += CGRectGetWidth([deleteButton bounds]) + 10;

		pageNum = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
		[pageNum setStringValue:@"No pages selected"];
		[pageNum setFont:[CPFont boldSystemFontOfSize:16.0]];
		[pageNum setTextColor:[CPColor whiteColor]];
		[pageNum sizeToFit];
		[pageNum setFrameOrigin: CGPointMake(bNextX, buttonTop)];
	}

	if(!aIndexSet || [aIndexSet count] == 0) {
		[scanButton removeFromSuperview];
		[deleteButton removeFromSuperview];
		[pageNum removeFromSuperview];
	} else {
		selectedPages = aIndexSet;
		var modPageNum = [selectedPages firstIndex] + 1;
		[pageNum setStringValue:[CPString stringWithFormat:@"Page %d", modPageNum]];
		[self addSubview:scanButton];
		[self addSubview:deleteButton];
		[self addSubview:pageNum];
	}
}

- (void)scan:(id)sender
{
	[_delegate scan];
}

- (void)remove:(id)sender
{
	[_delegate remove:selectedPages];
}

@end

@implementation AppController : CPObject
{
	CPDictionary photosets;
	CPCollectionView leftCollection;

	CPView rightView;
	CPCollectionView rightCollection;

	CPView pageControls;

	DataModel dataModel;
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

	[rightScrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable ];
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

	var rvBottom = CGRectGetHeight(rvBounds);

	pageControls = [[PageControls alloc] initWithFrame:CGRectMake(0,rvBottom-54,CGRectGetWidth(rvBounds), 54)];
	[pageControls setBackgroundColor: [CPColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[pageControls setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];
	[pageControls setDelegate:self];
	[pageControls buildPageControlsFor:nil];
	[rightView addSubview:pageControls];

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
	dataModel = [[DataModel alloc] initWithDelegate:self];
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
	if(aCollectionView == leftCollection) {
		var idx = [[leftCollection selectionIndexes] firstIndex],
		    record = [leftCollection content][idx];

		[rightCollection setSelectionIndexes: [CPIndexSet indexSet]];
		[rightCollection setContent:[[CPArray alloc] initWithArray:record.pages]];

	} else if(aCollectionView == rightCollection) {
		[pageControls buildPageControlsFor:[rightCollection selectionIndexes]];
	}
}

- (void)documentsDidChange:(CPDictionary)aDict
{
	[leftCollection setContent:[[aDict allValues] copy]];
	[self collectionViewDidChangeSelection:leftCollection];
}

- (void)scan
{
	alert("scanning page");
}

- (void)remove:(CPIndexSet)selectedPages
{
	var idx = [selectedPages firstIndex],
	    record = [rightCollection content][idx];

	[dataModel removePage:record.key];
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

	[textField setStringValue:anObject.name];
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
		[textField setTextColor:[CPColor whiteColor]];
		[textField setTextShadowColor:[CPColor blackColor]];
	} else {
		[highlightView removeFromSuperview];
		[textField setTextColor:[CPColor blackColor]];
		[textField setTextShadowColor:[CPColor whiteColor]];
	}
}

@end

@implementation PageCell : CPView
{
	CPImageView imageView;
	CPImage image;
	CPView highlightView;
}

- (void)setRepresentedObject:(JSObject)anObject
{
	if(!imageView) {
		imageView = [[CPImageView alloc] initWithFrame: [self bounds]];
		[imageView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[imageView setImageScaling:CPScaleProportionally];
		[imageView setHasShadow:YES];
		[self addSubview:imageView];
	}

	var pickey = anObject.key;
	var picfile = "/thumbnail/" + pickey + "?format=pagesized";
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
	if(!highlightView) {
		highlightView = [[CPView alloc] initWithFrame:[self bounds]];
		[highlightView setBackgroundColor:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0]];
		[highlightView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	}

	if(flag) {
		[highlightView setFrame:[self bounds]];
		[self addSubview:highlightView positioned:CPWindowBelow relativeTo:imageView];
	} else {
		[highlightView removeFromSuperview];
	}
}

- (void)imageDidLoad:(CPImage)anImage
{
	[imageView setImage:anImage];
}

@end

@implementation DataModel : CPObject
{
	CPDictionary data;
	id _delegate;
}

- (DataModel)initWithDelegate:(id)aDelagate
{
	_delegate = aDelagate;
	data = [[CPDictionary alloc] init];
	var request = [CPURLRequest requestWithURL:"/documents?format=json"];
	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
	return self;
}

- (void)removePage:(CPString)aKey
{
	// find the page
	var docKeys = [data allKeys];
	var docFound = NO;
	for(var i = 0; i < docKeys.length; i++) {
		var doc = [data objectForKey:docKeys[i]];

		var num_pages = doc.pages.length;
		for(var j = 0; j < num_pages; j++) {
			if(doc.pages[j].key === aKey) {
				if(j == 0) {
					doc.pages = doc.pages.slice(1);
				} else if (j == num_pages - 1) {
					doc.pages = doc.pages.slice(0, num_pages-1);
				} else {
					doc.pages = doc.pages.slice(0,j).concat(doc.pages.slice(j+1));
				}

				docFound = YES;
				break;
			}
		}

		if(docFound) {
			break;
		}
	}

	if(docFound) {
		[_delegate documentsDidChange:data]
	}
}

- (JSObject)getPages:(CPString)aString
{
	var record = [data objectForKey:aString];
	return record;
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)jsondata
{
	jsondata = eval(jsondata);
	for (var i = 0; i < jsondata.length; i++) {
		[data setObject:jsondata[i] forKey:jsondata[i].name]
	}
	[_delegate documentsDidChange:data]
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPString)error
{
	alert("error: "  + error);
}

@end

