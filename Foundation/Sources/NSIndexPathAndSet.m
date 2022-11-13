//
//  NSIndexPathSet.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Nov 22 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

// CODE NOT TESTED

#import "Foundation/NSIndexPath.h"
#import "Foundation/NSIndexSet.h"
#import "NSPrivate.h"

static NSIndexPath *_root;

@implementation NSIndexPath

- (NSString *) description;
{
	if(_parent)
		return [NSString stringWithFormat:@"%@.%u", [_parent description], _index];
	else
		return [NSString stringWithFormat:@"%u", _index];	// first
}

+ (NSIndexPath *) indexPathWithIndex:(NSUInteger) idx;
{
	return [self indexPathWithIndexes:&idx length:1];
}

+ (NSIndexPath *) indexPathWithIndexes:(NSUInteger *) idx
								length:(NSUInteger) len;
{
	return [[[self alloc] initWithIndexes:idx length:len] autorelease];
}

- (BOOL) isEqual:(id) obj;
{
	return obj == self;
}

- (NSComparisonResult) compare:(NSIndexPath *) obj;
{
	unsigned int i;
	unsigned int objLength=obj->_length;
	if(obj == self)
		return NSOrderedSame;	// must be the same
	for(i=0; i<_length && i < objLength; i++)
		{
		NSUInteger my=[self indexAtPosition:i];
		NSUInteger other=[obj indexAtPosition:i];
		if(my < other)
			return NSOrderedAscending;
		if(my > other)
			return NSOrderedDescending;			
		}
	if(_length < objLength)
		return NSOrderedAscending;
	if(_length > objLength)
		return NSOrderedDescending;
	return NSOrderedSame;	// all the same
}

- (void) getIndexes:(NSUInteger *) idx;
{
	if(_parent)
		[_parent getIndexes:idx];	// fill prefix part
	idx[_length]=_index;
}

- (NSUInteger) indexAtPosition:(NSUInteger) pos;
{ 
	if(pos > _length)
		return NSNotFound;
	while(pos < _length)
		self=_parent;	// go back
	return _index;
}

- (NSIndexPath *) indexPathByAddingIndex:(NSUInteger) idx;
{
	NSEnumerator *e=[_children objectEnumerator];	// optimize by using NSMapTable!
	NSIndexPath *child;
	// FIXME: this search could be optimized by a NSMapTable mapping child indexes to objects (if they exist)
	while((child=[e nextObject]))
		{
		if(child->_index == idx)
			return child;	// already stored
		}
	if(!_children)
		_children=[[NSMutableArray alloc] initWithCapacity:10];	// guess could be better estimated
	child=[[[self class] alloc] init];	// allocate a fresh node
	child->_parent=self;
	child->_length=_length+1;	// one level down
	child->_index=idx;
	// FIXME: should be a NSMapTable
	[_children addObject:child];
	return [child autorelease];
}

- (NSIndexPath *) indexPathByRemovingLastIndex;
{
	return _parent;
}

- (NSUInteger) length; { return _length; }

- (id) initWithIndex:(NSUInteger) index;
{
	return [self initWithIndexes:&index length:1];
}

- (id) initWithIndexes:(NSUInteger *) idx length:(NSUInteger) len;
{
	if(!_root)
		_root=self;	// first call: make us the root object
	else
		[self release];
	self=_root;
	while(len-- > 0)
		self=[self indexPathByAddingIndex:*idx++];	// walk through tree creating subnodes if needed
	return [self retain];
}

- (void) dealloc;
{
	[_children release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone; { return [self retain]; }	// not really copied - allows to use us as a key for NSDictionary

- (void) encodeWithCoder:(NSCoder *) coder;
{
	// encode length
	// encode indexes
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	// decode length
	// crate temp buffer
	// decode indexes
//	return [self initWithIndexes:&index length:length];
	return NIMP;
}

@end

@implementation NSIndexSet

+ (id) indexSet; { return [[self new] autorelease]; }
+ (id) indexSetWithIndex:(NSUInteger) value; { return [[[self alloc] initWithIndex:value] autorelease]; }
+ (id) indexSetWithIndexesInRange:(NSRange) range; { return [[[self alloc] initWithIndexesInRange:range] autorelease]; }

- (id) copyWithZone:(NSZone *) zone;
{
	return [self retain];
}

- (id) mutableCopyWithZone:(NSZone *) zone;
{
	return [[NSMutableIndexSet allocWithZone:zone] initWithIndexSet:self];
}

- (id) init;
{
	if((self=[super init]))
		{
		// no special initialization - _nranges==0
		}
	return self;
}

- (void) dealloc;
{
	if(_indexRanges)
		objc_free(_indexRanges);
	[super dealloc];
}

- (NSString *) description;
{
	NSString *r=nil;
	NSUInteger i;
	if(_nranges == 0)
		return @"<empty>";	// empty indexset
	for(i=0; i<_nranges; i++)
		{
		if(r)
			r=[r stringByAppendingFormat:_indexRanges[i].length==1?@"%@,%u":@"%@, %u-%u", r, _indexRanges[i].location, NSMaxRange(_indexRanges[i])-1];
		else
			r=[NSString stringWithFormat:_indexRanges[i].length==1?@"%u":@"%u-%u", _indexRanges[i].location, NSMaxRange(_indexRanges[i])-1];
		}
	return r;
}

- (id) initWithIndex:(NSUInteger) value; { return [self initWithIndexesInRange:NSMakeRange(value, 1)]; }

- (id) initWithIndexesInRange:(NSRange) range;
{
	if((self=[super init]))
		{
		_nranges=1;
		_indexRanges=(NSRange *) objc_malloc(sizeof(_indexRanges[0]));	// allocate one element
		_indexRanges[0]=range;	// store
		}
	return self;
}

- (id) initWithIndexSet:(NSIndexSet *) other;
{
	if((self=[super init]))
		{
		_nranges=other->_nranges;
		_indexRanges=(NSRange *) objc_malloc(_nranges*sizeof(_indexRanges[0]));	// allocate one element
		memcpy(_indexRanges, other->_indexRanges, _nranges*sizeof(_indexRanges[0]));	// copy
		}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[coder encodeValueOfObjCType:@encode(unsigned int) at:&_nranges];
	[coder encodeArrayOfObjCType:@encode(NSRange) count:_nranges at:_indexRanges];
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super init]))
		{
		[coder decodeValueOfObjCType:@encode(unsigned int) at:&_nranges];
		_indexRanges=(NSRange *) objc_malloc(_nranges*sizeof(_indexRanges[0]));	// allocate elements
		[coder decodeArrayOfObjCType:@encode(NSRange) count:_nranges at:_indexRanges];
		}
	return self;
}

- (BOOL) isEqual:(id) indexSet;
{
	return [indexSet isKindOfClass:[self class]] && [self isEqualToIndexSet:indexSet];
}

- (BOOL) isEqualToIndexSet:(NSIndexSet *) other;
{ // segments must be identical since we don't allow overlapping subranges adjacent segments
	NSUInteger i;
	if(_nranges != other->_nranges)
		return NO;
	for(i=0; i<_nranges; i++)
		{
		if(!NSEqualRanges(_indexRanges[i], other->_indexRanges[i]))
			return NO;
		}
	return YES;
}

- (BOOL) containsIndex:(NSUInteger) value;
{
	NSUInteger i;
	for(i=0; i<_nranges; i++)
		{
		if(NSLocationInRange(value, _indexRanges[i]))
			return YES;
		}
	return NO;
}

- (BOOL) containsIndexes:(NSIndexSet *) other;
{ // contains ALL indexes of the other set
	NIMP;
	return NO;
}

- (BOOL) containsIndexesInRange:(NSRange) range;
{ // there must be a segment that completely overlaps with range (there can't be two because they should have been merged!)
	NSUInteger i;
	// we could even search faster by splitting the total set of ranges in halves because they are sorted
	for(i=0; i<_nranges; i++)
		{
		if(NSEqualRanges(NSIntersectionRange(range, _indexRanges[i]), range))
			return YES;
		}
	return NO;
}

- (BOOL) intersectsIndexesInRange:(NSRange) range;
{ // if any index is in the set
	NSUInteger i;
	for(i=0; i<_nranges; i++)
		{
		if(NSIntersectionRange(range, _indexRanges[i]).length != 0)
			return YES;
		}
	return NO;
}

- (NSUInteger) count;
{
	NSUInteger i;
	if(!_count1)
		{ // value should be cached!
		_count1=1;	// one more...
		for(i=0; i<_nranges; i++)
			_count1+=_indexRanges[i].length;	// sum up
		}
	return _count1-1;
}

- (NSUInteger) hash
{ // hashing must be fast!
	if(!_count1) [self count];	// recache
	return _count1;	// should be a good indicator...
}

- (NSUInteger) firstIndex;
{
	if(_nranges == 0) return NSNotFound;
	return _indexRanges[0].location;
}

- (NSUInteger) lastIndex;
{
	if(_nranges == 0) return NSNotFound;
	return NSMaxRange(_indexRanges[_nranges-1])-1;	// last index
}

- (NSUInteger) indexGreaterThanIndex:(NSUInteger) value;
{
	NSUInteger i=0;
	while(i<_nranges)
		{
		if(_indexRanges[i].location > value)
			return _indexRanges[i].location;	// range segment beyond
		if(NSLocationInRange(value+1, _indexRanges[i]))
			return value+1;	// next index falls into this subrange
		i++;
		}
	return NSNotFound;
}

- (NSUInteger) indexGreaterThanOrEqualToIndex:(NSUInteger) value;
{
	NSUInteger i=0;
	while(i<_nranges)
		{
		if(_indexRanges[i].location > value)
			return _indexRanges[i].location;	// range segment is beyond
		if(NSLocationInRange(value, _indexRanges[i]))
			return value;	// falls into this subrange
		i++;
		}
	return NSNotFound;
}

- (NSUInteger) indexLessThanIndex:(NSUInteger) value;
{
	NSUInteger i=_nranges;
	while(i-- > 0)
		{
		if(NSMaxRange(_indexRanges[i]) <= value)
			return NSMaxRange(_indexRanges[i])-1;	// range segment before
		if(NSLocationInRange(value-1, _indexRanges[i]))
			return value-1;	// previous index falls into this subrange
		}
	return NSNotFound;
}

- (NSUInteger) indexLessThanOrEqualToIndex:(NSUInteger) value;
{
	NSUInteger i=_nranges;
	while(i-- > 0)
		{
		if(NSMaxRange(_indexRanges[i]) <= value)
			return NSMaxRange(_indexRanges[i])-1;	// range segment before
		if(NSLocationInRange(value, _indexRanges[i]))
			return value;	//index falls into this subrange
		}
	return NSNotFound;
}

- (NSUInteger) getIndexes:(NSUInteger *) buffer
				   maxCount:(NSUInteger) cnt
			   inIndexRange:(NSRangePointer) indexRange;
{
	NSUInteger i;
	NSUInteger c0=cnt;
	if(!indexRange)
		{ // unlimited
		for(i=0; i<_nranges && cnt > 0; i++)
			{
			NSUInteger val=_indexRanges[i].location;
			NSUInteger last=NSMaxRange(_indexRanges[i]);
			while(val < last && cnt > 0)
				*buffer++=val++, cnt--;
			}
		}
	else
		{
		for(i=0; i<_nranges && NSMaxRange(_indexRanges[i]) < indexRange->location; i++)
			; // find first relevant block
		for(; i<_nranges && cnt > 0; i++)
			{ // extract next index block
			NSUInteger val=_indexRanges[i].location;
			NSUInteger last=NSMaxRange(_indexRanges[i]);
			if(val < indexRange->location)
				val=indexRange->location;	// don't start before requested range
			if(last > NSMaxRange(*indexRange))
				last=NSMaxRange(*indexRange);	// limit to end of requested range
			if(last < val)
				break;	// already done and nothing more to add
			while(val < last && cnt > 0)
				*buffer++=val++, cnt--;
			}
		// update indexRange
		}
	return c0-cnt;	// number of entries copied
}

- (NSUInteger) countOfIndexesInRange:(NSRange) value
{
	unsigned int i=0;
	NSUInteger count=0;
	while(i<_nranges)
			{
				NSRange isect=NSIntersectionRange(value, _indexRanges[i]);
				count+=isect.length;
				i++;
			}
	return count;
}

@end


@implementation NSMutableIndexSet

- (id) initWithIndex:(NSUInteger) value;
{
	self=[super initWithIndex:value];
	if(self)
		_capacity=_nranges;	// that is what we currently have allocated
	return self;
}

- (id) initWithIndexesInRange:(NSRange) range;
{
	self=[super initWithIndexesInRange:range];
	if(self)
		_capacity=_nranges;	// that is what we currently have allocated
	return self;
}

- (id) initWithIndexSet:(NSIndexSet *) other;
{
	self=[super initWithIndexSet:other];
	if(self)
		_capacity=_nranges;	// that is what we currently have allocated
	return self;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	self=[super initWithCoder:coder];
	if(self)
		_capacity=_nranges;	// that is what we currently have allocated
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{ // immutable copy of mutable object
	return [[NSIndexSet allocWithZone:zone] initWithIndexSet:self];
}

- (id) mutableCopyWithZone:(NSZone *) zone;
{
	return [[NSMutableIndexSet allocWithZone:zone] initWithIndexSet:self];
}

- (void) _addIndexesInRanges:(NSRangePointer) ranges count:(unsigned) count;
{
	NSUInteger i=0, j;
	for(j=0; j<count; j++)
		{
		NSRange range=ranges[j];
#if 1
		NSLog(@"addIndexesInRange: %@", NSStringFromRange(range));
#endif
		while(i<_nranges)
			{
			if(NSIntersectionRange(range, _indexRanges[i]).length != 0)
				{ // first overlapping range found - extend and merge with other ranges if needed
				_indexRanges[i]=NSUnionRange(range, _indexRanges[i]);	// extend as/if necessary
				_count1=0;	// recache
				while(i+1 < _nranges && NSIntersectionRange(_indexRanges[i], _indexRanges[i+1]).length != 0)
					{ // merge with all following ranges that are now covered
					_indexRanges[i]=NSUnionRange(_indexRanges[i], _indexRanges[i+1]);	// extend as/if necessary
#if 1
					NSLog(@"memmove(%lu, %lu, %lu) of %d", i+1, i+2, _nranges-i-2, _nranges);
#endif
					memmove(&_indexRanges[i+1], &_indexRanges[i+2], sizeof(_indexRanges[0])*(_nranges-i-2));	// delete range that has been merged
					_nranges--;	// one less!
					}
#if 1
				NSLog(@"result: %@", self);
#endif
				goto loop;	// I know this is evil but saves an additional comparison or flag why we did break...
				}
			if(NSMaxRange(range) < _indexRanges[i].location)
				break;	// should have been inserted here
			i++;
			}
		if(_nranges == _capacity)
			{
#if 1
			NSLog(@"increase capacity (%d)", _capacity);
#endif
			_indexRanges=(NSRange *) objc_realloc(_indexRanges, sizeof(_indexRanges[0])*(_capacity=2*_capacity+5));	// make more room
#if 1
			NSLog(@"increased capacity (%d)", _capacity);
#endif
			}
		memmove(&_indexRanges[i+1], &_indexRanges[i], sizeof(_indexRanges[0])*(_nranges-i));
		_indexRanges[i]=range;
		_count1=0;	// recache
		_nranges++;	// we now have one more
loop: ;
		}
#if 1
	NSLog(@"result: %@", self);
#endif
}

- (void) addIndex:(NSUInteger) value;
{
	NSRange range=NSMakeRange(value, 1);
	[self _addIndexesInRanges:&range count:1];
}

- (void) addIndexes:(NSIndexSet *) other;
{ // add all segments
	[self _addIndexesInRanges:other->_indexRanges count:other->_nranges];
}

- (void) addIndexesInRange:(NSRange) range;
{
	[self _addIndexesInRanges:&range count:1];
}

- (void) _removeIndexesInRanges:(NSRangePointer) ranges count:(NSUInteger) count;
{
	NSUInteger i=0, j;
	for(j=0; j<count; j++)
		{
		NSRange range=ranges[j];
		NSRange inter;
#if 0
		NSLog(@"removeIndexesInRange: %@", NSStringFromRange(range));
#endif
		while(i<_nranges && NSMaxRange(_indexRanges[i]) <= NSMaxRange(range))
			{
			if(NSIntersectionRange(range, _indexRanges[i]).length == _indexRanges[i].length)
				{ // completely falls into current range - completely delete
#if 0
				NSLog(@"memmove(%d, %d, %d) of %d", i+1, i+2, _nranges-i-2, _nranges);
#endif
				memmove(&_indexRanges[i], &_indexRanges[i+1], sizeof(_indexRanges[0])*(_nranges-i-1));	// delete range
				_nranges--;	// one less!
				_count1=0;	// recache
				continue;
				}
			inter=NSIntersectionRange(range, _indexRanges[i]);
			if(inter.length != 0)
				{ // overlap remains
				if(inter.location != _indexRanges[i].location && NSMaxRange(inter) != NSMaxRange(_indexRanges[i]))
					{ // middle overlap -> split (i.e. delete (3-5) from (1-7) -> (1-2,6-7)
					if(_nranges == _capacity)
						{
#if 0
						NSLog(@"increase capacity (%d)", _capacity);
#endif
						_indexRanges=(NSRange *) objc_realloc(_indexRanges, sizeof(_indexRanges[0])*(_capacity+=3));	// make more room
#if 0
						NSLog(@"increased capacity (%d)", _capacity);
#endif
						}
					memmove(&_indexRanges[i+1], &_indexRanges[i], sizeof(_indexRanges[0])*(_nranges-i));
					// FIXME:
					_indexRanges[i+1].location=NSMaxRange(range);										// second subrange
					_indexRanges[i+1].length=NSMaxRange(_indexRanges[i])-_indexRanges[i+1].location;	// second subrange
					_indexRanges[i].length=range.location-_indexRanges[i].location;						// first subrange
					_nranges++;	// we now have one more
					}
				else
					_indexRanges[i]=inter;	// reduce to intersection
				_count1=0;	// recache
				}
			else
				i++;	// no intersection
			}
		}
#if 0
	NSLog(@"result: %@", self);
#endif
}

- (void) removeIndex:(NSUInteger) value;
{
	NSRange range=NSMakeRange(value, 1);
	[self _removeIndexesInRanges:&range count:1];
}

- (void) removeIndexes:(NSIndexSet *) other;
{ // remove all segments
	[self _removeIndexesInRanges:other->_indexRanges count:other->_nranges];
}

- (void) removeIndexesInRange:(NSRange) range;
{
	[self _removeIndexesInRanges:&range count:1];
}

- (void) removeAllIndexes;
{
	_nranges=0;
}

- (void) shiftIndexesStartingAtIndex:(NSUInteger) index by:(NSInteger) delta;
{
	if(delta < 0)
		[self removeIndexesInRange:NSMakeRange(index-delta, delta)];	// ensure they don't exist
	// find block which contains starting index
	// if starting index is not _firstIndex, split into two ranges so that we can really shift
	// add delta to all firstIndex values until end
				_count1=0;	// recache
	NIMP;
} 

@end
