/*
 * AppController.j
 * Scan Server
 *
 * Created by Brian Taylor January 2010
 * Copyright 2010, WuboNet
 */

@import <Foundation/CPObject.j>
@import "PageControls.j"
@import "DocumentView.j"
@import "PageView.j"

DocumentDragType = "DocumentDragType";

@implementation AppController : CPObject
{
	DocumentView documentView;

	CPView rightView;
	PageView pageView;

	CPView pageControls;
	JSObject _selectedDocument;

	DataModel dataModel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

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

	pageControls = [[PageControls alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rvBounds), 54)];
	[pageControls setBackgroundColor: [CPColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[pageControls setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	[pageControls setDelegate:self];
	[pageControls buildPageControlsFor:nil withSelection:nil];
	[rightView addSubview:pageControls];

	pageView = [[PageView alloc]
		initWithFrame:CGRectMake(0,54,CGRectGetWidth(rvBounds),CGRectGetHeight(rvBounds)-54)
		andDelegate:self];

	[pageView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable ];
	[rightView addSubview:pageView];

	// build the left pane
	documentView = [[DocumentView alloc]
		initWithFrame:CGRectMake(0,0,200, CGRectGetHeight(svBounds))
		andDelegate:self];
	[documentView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable ];

	[splitView addSubview:documentView];
	[splitView addSubview:rightView];

	[contentView addSubview:splitView];

    [theWindow orderFront:self];

	// fetch the document data
	dataModel = [[DataModel alloc] initWithDelegate:self];
}

- (void)pageSelected:(JSObject)aPage atIndex:(int)idx
{
	[pageControls buildPageControlsFor:_selectedDocument withSelection:idx];
}

- (void)documentSelected:(JSObject)aDoc
{	
	[pageView setContent:aDoc.pages];
	[pageView setSelectionIndexes: [CPIndexSet indexSet]];
	[pageControls buildPageControlsFor:aDoc withSelection:-1];
}

- (void)documentItem:(JSObject)aDoc receivedPage:(JSObject)aPage
{
	alert("doc " + aDoc.name + " got page " + aPage.key);
}

/*
- (CPArray)collectionView:(CPCollectionView)aView dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
	if (aView == leftCollection) {
		return [DocumentDragType];
	} else {
		return undefined;
	}
}
*/

- (void)documentsDidChange:(CPDictionary)aDict
{
	var sortFunction = function(lhs, rhs) {
		if(lhs.name == rhs.name) {
			return CPOrderedSame;
		} else if(lhs.name < rhs.name) {
			return CPOrderedAscending;
		} else {
			return CPOrderedDescending;
		}
	}

	var values = [[aDict allValues] copy];
	[values sortUsingFunction:sortFunction context:nil];

	[documentView setContent:values];

	var currDoc = [documentView selected];
	if(currDoc) {
		[pageView setContent:currDoc.pages];
	}

	// can stop the spinner
}

- (void)scanForDocument:(JSObject)aDoc
{
	[dataModel scanForDocument:aDoc];
	// TODO: turn on a spinner or something
}

- (void)remove:(int)selectedPage
{
	var record = [pageView content][selectedPage];

	[dataModel removePage:record.key];
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

