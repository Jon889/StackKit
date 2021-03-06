//
//  _SKRequestBuilderUsersWithBadge.m
//  StackKit
/**
  Copyright (c) 2011 Dave DeLong
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 **/

#import "_SKRequestBuilderUsersWithBadge.h"
#import "SKUser.h"

@implementation _SKRequestBuilderUsersWithBadge

+ (Class) recognizedFetchEntity {
	return [SKUser class];
}

+ (NSDictionary *) recognizedPredicateKeyPaths {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			SK_BOX(NSGreaterThanOrEqualToPredicateOperatorType, NSLessThanOrEqualToPredicateOperatorType), @"creationDate",
			SK_BOX(NSContainsPredicateOperatorType), @"awardedBadges.badges",
			nil];
}

+ (NSSet *) requiredPredicateKeyPaths {
	return [NSSet setWithObjects:
			@"awardedBadges.badges",
			nil];
}

+ (BOOL) recognizesASortDescriptor {
	return NO;
}

- (void) buildURL {
	NSPredicate * p = [self requestPredicate];
	id badges = [p sk_constantValueForLeftKeyPath:@"awardedBadges.badges"];
	[self setPath:[NSString stringWithFormat:@"/badges/%@", SKExtractBadgeID(badges)]];
	
	SKRange r = [p sk_rangeOfConstantValuesForLeftKeyPath:@"creationDate"];
	if (r.lower != SKNotFound) {
		[[self query] setObject:r.lower forKey:SKQueryFromDate];
	}
	if (r.upper != SKNotFound) {
		[[self query] setObject:r.upper forKey:SKQueryToDate];
	}
	[super buildURL];
}

@end
