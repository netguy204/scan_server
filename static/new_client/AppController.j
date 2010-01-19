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
	JSObject _theDoc;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

- (void)buildPageControlsFor:(JSObject)aDoc withSelection:(CPIndexSet)aIndexSet
{
	if(!scanButton) {
		var pcBounds = [self bounds];

		scanButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
		[scanButton setTitle:@"Scan Page"];
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
		[scanButton setFrameOrigin: CGPointMake(bNextX-CGRectGetWidth(bBounds), buttonTop)];
		[scanButton setTarget:self];
		[scanButton setAction:@selector(scan:)];
		[scanButton setAutoresizingMask:CPViewMinXMargin];
		bNextX -= CGRectGetWidth(bBounds) - 10;
	}

	_theDoc = aDoc;
	if(_theDoc) {
		[self addSubview:scanButton];
	} else {
		[scanButton removeFromSuperview];
	}

	if(!aIndexSet || [aIndexSet count] == 0) {
		[deleteButton removeFromSuperview];
		[pageNum removeFromSuperview];
	} else {
		selectedPages = aIndexSet;
		var modPageNum = [selectedPages firstIndex] + 1;
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
	JSObject _selectedDocument;

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

	var rvBottom = CGRectGetHeight(rvBounds);
	pageControls = [[PageControls alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rvBounds), 54)];
	[pageControls setBackgroundColor: [CPColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[pageControls setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	[pageControls setDelegate:self];
	[pageControls buildPageControlsFor:nil withSelection:nil];
	[rightView addSubview:pageControls];

	
	var rightScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0,54,CGRectGetWidth(rvBounds),CGRectGetHeight(rvBounds)-54)],
	    rsvBounds = [rightScrollView bounds];

	[rightScrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable ];
	[rightScrollView setAutohidesScrollers:YES];
	
	rightCollection = [[CPCollectionView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rsvBounds),0)];
	[rightCollection setDelegate:self];

	var rcItemSz = CGSizeMake(CGRectGetWidth(rsvBounds), CGRectGetHeight(rsvBounds)-40);
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
	[leftCollection setMinItemSize:CGSizeMake(20.0, 25.0)];
	[leftCollection setMaxItemSize:CGSizeMake(1000.0, 25.0)];
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
		_selectedDocument = record;
		[rightCollection setSelectionIndexes: [CPIndexSet indexSet]];

		if(record) {
			[rightCollection setContent:[[CPArray alloc] initWithArray:record.pages]];
		}

	} else if(aCollectionView == rightCollection) {
		[pageControls buildPageControlsFor:_selectedDocument withSelection:[rightCollection selectionIndexes]];
	}
}

- (void)documentsDidChange:(CPDictionary)aDict
{
	[leftCollection setContent:[[aDict allValues] copy]];
	[self collectionViewDidChangeSelection:leftCollection];

	// can stop the spinner
}

- (void)scanForDocument:(JSObject)aDoc
{
	[dataModel scanForDocument:aDoc];
	// TODO: turn on a spinner or something
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
		textField = [[CPTextField alloc] initWithFrame:CGRectInset([self bounds],2,2)];
		[textField setFont:[CPFont systemFontOfSize:12.0]];
		[textField setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[textField setTextColor:[CPColor blackColor]];
		[textField setTextShadowColor:[CPColor whiteColor]];
		[textField setTextShadowOffset:CGSizeMake(1,1)];
		[self addSubview:textField];
	}

	[textField setStringValue:anObject.name];
}

- (void)setSelected:(BOOL)flag
{
	if(!highlightView) {
		highlightView = [[CPView alloc] initWithFrame:[self bounds]];
		//[highlightView setBackgroundColor:[CPColor grayColor]];
		[highlightView setBackgroundColor:[CPColor colorWithRed:200.0/255 green:210.0/255.0 blue:220.0/255.0 alpha:1.0]];
		[highlightView setAutoresizingMask:CPViewWidthSizable];
	}

	if(flag) {
		[self addSubview:highlightView positioned:CPWindowBelow relativeTo:textField];
		[textField setTextColor:[CPColor whiteColor]];
		[textField setTextShadowColor:[CPColor blackColor]];
		//[textField setTextFieldBackgroundColor:[CPColor colorWithRed:213.0/255 green:221.0/255.0 blue:230.0/255.0 alpha:1.0]];
	} else {
		[highlightView removeFromSuperview];
		[textField setTextColor:[CPColor blackColor]];
		[textField setTextShadowColor:[CPColor whiteColor]];
		//[textField setTextFieldBackgroundColor:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0]];
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

	CPURLConnection documentConnection;
	CPURLConnection scanConnection;
}

- (DataModel)initWithDelegate:(id)aDelagate
{
	_delegate = aDelagate;
	data = [[CPDictionary alloc] init];
	var DOCUMENT_URL = "/documents?format=json";
	var request = [CPURLRequest requestWithURL:DOCUMENT_URL];
	documentConnection = [CPURLConnection connectionWithRequest:request delegate:self];
	return self;
}

- (void)removePage:(CPString)aKey
{
	// find the page
	var docKeys = [data allKeys];
	var docFound = NO;
	for(var i = 0; i < docKeys.length; i++) {
		var doc = [data objectForKey:docKeys[i]];
		var newArray = removeItem(doc.pages, pageKeySelector, aKey);
		if(newArray) {
			doc.pages = newArray;
			docFound = YES;
			break;
		}
	}

	var REMOVE_URL = "/remove/" + aKey + "?format=json";
	var request = [CPURLRequest requestWithURL:REMOVE_URL];
	var connection = [CPURLConnection connectionWithRequest:request delegate:self];

	if(docFound) {
		[_delegate documentsDidChange:data]
	}
}

- (void)scanForDocument:(JSObject)aDoc
{
	var SCAN_URL = "/scan_";
	var request = [CPURLRequest requestWithURL:SCAN_URL + aDoc.key + ".png?format=json"];
	scanConnection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (JSObject)getPages:(CPString)aString
{
	var record = [data objectForKey:aString];
	return record;
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)jsondata
{
	jsondata = eval(jsondata);
	if(aConnection == documentConnection) {
		// do something special
	} else if(aConnection == scanConnection) {
		// do something special
	} else {
		// alert("page removed!");
	}

	for (var i = 0; i < jsondata.length; i++) {
		var oldObj = [data objectForKey:jsondata[i].key];
		if(oldObj) {
			// update the things that can change
			oldObj.name = jsondata[i].name;
			oldObj.pages = jsondata[i].pages;
		} else {
			[data setObject:jsondata[i] forKey:jsondata[i].key]
		}
	}

	[_delegate documentsDidChange:data]
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPString)error
{
	alert("error: "  + error);
}

@end

// utility functions
function removeItem(aList, aSelector, aItem) {
	var num_items = aList.length;
	for(var j = 0; j < num_items; j++) {
		if(aSelector(aList[j]) === aItem) {
			if(j == 0) {
				return aList.slice(1);
			} else if (j == num_items - 1) {
				return aList.slice(0, num_items-1);
			} else {
				return aList.slice(0,j).concat(aList.slice(j+1));
			}
		}
	}
	return undefined;
}

function pageKeySelector(page) {
	return page.key;
}

