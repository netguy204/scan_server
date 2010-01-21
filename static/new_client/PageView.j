/*
 * PageView.j
 * Scan Server
 *
 * Created by Brian Taylor January 2010
 * Copyright 2010, WuboNet
 */

@import <Foundation/CPObject.j>

PageDragType = "PageDragType";

@implementation PageView : CPScrollView
{
	CPCollectionView pages;
	id _delegate;
}

- (void)initWithFrame:aFrame andDelegate:(id)aDelegate
{
	[super initWithFrame:aFrame];

	_delegate = aDelegate;

	var rsvBounds = [self bounds];
	[self setAutohidesScrollers:YES];

	pages = [[CPCollectionView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(rsvBounds),0)];

	var rcItemSz = CGSizeMake(CGRectGetWidth(rsvBounds), CGRectGetHeight(rsvBounds)-40);

	[pages setMinItemSize:rcItemSz];
	[pages setMaxItemSize:rcItemSz];
	[pages setMaxNumberOfColumns:1];
	[pages setVerticalMargin:0.0];
	[pages setAutoresizingMask:CPViewWidthSizable];
	[pages setDelegate:self];

	// build the prototype item
	var pageItem = [[CPCollectionViewItem alloc] init];
	[pageItem setView:[[PageCell alloc] initWithFrame:CGRectMakeZero()]];
	[pages setItemPrototype:pageItem];

	[self setDocumentView:pages];

	return self;
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
	var idx = [[aCollectionView selectionIndexes] firstIndex],
	    record = [aCollectionView content][idx];

	[_delegate pageSelected:record atIndex:idx];
}

- (void)setContent:(JSObject)content
{
	[pages setContent:content];
}

- (void)setSelectionIndexes:(CPIndexSet)aSet
{
	[pages setSelectionIndexes:aSet];
}

- (CPArray)collectionView:(CPCollectionView)aView dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
	return [PageDragType];
}

- (CPData)collectionView:(CPCollectionView)aView dataForItemsAtIndexes:(CPIndexSet)indices forType:(CPString)aType
{
	var firstIndex = [indices firstIndex],
	    content = [aView content][firstIndex];
	return [CPKeyedArchiver archivedDataWithRootObject:content];
}

- (JSObject)content
{
	return [pages content];
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

