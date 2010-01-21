/*
 * DocumentView.j
 * Scan Server
 *
 * Created by Brian Taylor January 2010
 * Copyright 2010, WuboNet
 */

@import <Foundation/CPObject.j>

@implementation DocumentView : CPScrollView
{
	CPCollectionView docView;
	JSObject _selectedDocument;
	id _delegate;
}

- (void)initWithFrame:aFrame andDelegate:(id)aDelegate
{
	[super initWithFrame:aFrame];
	
	_delegate = aDelegate;

	[self setAutohidesScrollers:YES];
	var ourBounds = [self bounds];
	
	docView = [[CPCollectionView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(ourBounds), 0)];

	[docView setDelegate:self];
	[docView setMinItemSize:CGSizeMake(20.0, 25.0)];
	[docView setMaxItemSize:CGSizeMake(1000.0, 25.0)];
	[docView setMaxNumberOfColumns:1];
	[docView setVerticalMargin:0.0];
	[docView setAutoresizingMask:CPViewWidthSizable ];

	var docItem = [[CPCollectionViewItem alloc] init];
	var prototypeDocCell = [[DocumentCell alloc] initWithFrame:CGRectMake(0,0,150,150)];

	[docItem setView:prototypeDocCell];
	[docView setItemPrototype:docItem];
	[self setDocumentView:docView];

	return self;
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
	var idx = [[aCollectionView selectionIndexes] firstIndex],
		record = [aCollectionView content][idx];
	_selectedDocument = record;

	if(record) {
		[_delegate documentSelected:record];
	}
}

- (void)setContent:(JSObject)content
{
	[docView setContent:content];
}

- (JSObject)selected
{
	return _selectedDocument;
}

- (void)documentItem:(JSObject)aDoc receivedPage:(JSObject)aPage
{
	[_delegate documentItem:aDoc receivedPage:aPage];
}

@end

@implementation DocumentCell : CPView
{
	CPTextField textField;
	CPView highlightView;
	JSObject ourObject;
	BOOL _isActive;
}

- (void)initWithFrame:aFrame
{
	[super initWithFrame:aFrame];
	return self;
}

- (void)setActive:(BOOL)isActive
{
	_isActive = isActive;
	if(isActive) {
		[textField setFont:[CPFont boldSystemFontOfSize:12.0]];
	} else {
		[textField setFont:[CPFont systemFontOfSize:12.0]];
	}
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
		[self registerForDraggedTypes:[CPArray arrayWithObjects:PageDragType]];
	}

	[textField setStringValue:anObject.name];
	ourObject = anObject;
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

- (void)performDragOperation:(CPDraggingInfo)aSender
{
	var data = [[aSender draggingPasteboard] dataForType:PageDragType],
	    pageData = [CPKeyedUnarchiver unarchiveObjectWithData:data];

	// crazy sick hack to get the document view because the state I'm
	// constructed with goes away for some reason
	var super1 = [self superview],
	    super2 = [super1 superview],
		super3 = [super2 superview];

	[super3 documentItem:ourObject receivedPage:pageData];
	[self setActive:NO];
}

- (void)draggingEntered:(CPDraggingInfo)aSender
{
	[self setActive:YES];
}

- (void)draggingExited:(CPDraggingInfo)aSender
{
	[self setActive:NO];
}

@end

