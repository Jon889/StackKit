//
//  SKUserTest.m
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

#import "SKUserTest.h"
#import "SKTestConstants.h"
#import <StackKit/StackKit.h>
#import "SKFetchRequest+Private.h"
#import "SKRequestBuilder.h"

@implementation SKUserTest

- (void) testUserAPICall {
	SKSite * site = [[SKSiteManager sharedManager] stackOverflowSite];
	
	SKFetchRequest * request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKUser class]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"userID = %@", [NSNumber numberWithInt:115730]]];
	
	NSArray * results = [site executeSynchronousFetchRequest:request];
	STAssertTrue([results count] == 1, @"request should return 1 object");
	
	SKUser * davedelong = [results objectAtIndex:0];
	STAssertEqualObjects([davedelong displayName], @"Dave DeLong", @"incorrect user displayName");
	STAssertEqualObjects([davedelong userID], [NSNumber numberWithInt:115730], @"incorrect user id");
	
//	STAssertTrue([[davedelong acceptRate] floatValue] > 0.0f, @"accept rate should be greater than 0");
}

- (void) testMultipleUsersAPICall {
	SKSite * site = [[SKSiteManager sharedManager] stackOverflowSite];
	
	SKFetchRequest * request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKUser class]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"userID = %@", [NSArray arrayWithObjects:[NSNumber numberWithInt:115730],[NSNumber numberWithInt:382190],nil]]];
	
	NSArray * results = [site executeSynchronousFetchRequest:request];
	STAssertTrue([results count] == 2, @"request should return 2 objects");
	
	SKUser * davedelong = [results objectAtIndex:0];
	STAssertEqualObjects([davedelong displayName], @"Dave DeLong", @"incorrect user displayName");
	STAssertEqualObjects([davedelong userID], [NSNumber numberWithInt:115730], @"incorrect user id");
	
	SKUser * tonklon = [results objectAtIndex:1];
	STAssertEqualObjects([tonklon displayName], @"tonklon", @"incorrect user displayName");
	STAssertEqualObjects([tonklon userID], [NSNumber numberWithInt:382190], @"incorrect user id");
	
	STAssertTrue([[davedelong acceptRate] floatValue] > 0.0f, @"accept rate should be greater than 0");
}

- (void) testOldestUsers {
	SKSite * site = [[SKSiteManager sharedManager] stackOverflowSite];
	
	SKFetchRequest * request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKUser class]];
	[request setSortDescriptor:[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES] autorelease]];
	[request setFetchLimit:10];
	
	NSArray * users = [site executeSynchronousFetchRequest:request];
	NSLog(@"%@", [request error]);
	
	STAssertTrue([users count] == 10, @"only 10 users should've been fetched: %@", users);
	
	STAssertNil([request error], @"error should be nil: %@", [request error]);
	[request release];
	
	NSArray * returnedCreationDates = [users valueForKey:@"creationDate"];
	
	NSDate * previousDate = nil;
	for (NSDate * date in returnedCreationDates) {
		if (previousDate != nil) {
			STAssertTrue([previousDate earlierDate:date] == previousDate, @"out-or-order user! (%@ >=? %@", previousDate, date);
		}
		previousDate = date;
	}
}

- (void) testUserFilter {
	SKSite * site = [[SKSiteManager sharedManager] stackOverflowSite];
	
	SKFetchRequest * request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKUser class]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"displayName CONTAINS %@", @"Dave DeLong"]];
	
	NSError * error = nil;
	NSArray * matches = [site executeSynchronousFetchRequest:request];
	[request release];
	
	NSLog(@"%@", matches);
	
	STAssertNil(error, @"error should be nil");
	STAssertTrue([matches count] == 1, @"matches should only have 1 object");
	
	SKUser * davedelong = [matches objectAtIndex:0];
	STAssertEqualObjects([davedelong userID], [NSNumber numberWithInt:115730], @"non-matching user id");
}

- (void) testUsersWithMostFavoritedQuestions {
	SKSite * site = [[SKSiteManager sharedManager] stackAppsSite];
	
	SKFetchRequest * request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKQuestion class]];
	
	NSCountedSet * counts = [NSCountedSet set];
	
	NSUInteger count = NSUIntegerMax;
	for (NSUInteger offset = 0; offset < count; offset += 100) {
		[request setFetchOffset:offset];
		
		NSArray * matches = [site executeSynchronousFetchRequest:request];
		for (SKQuestion * question in matches) {
			NSUInteger count = [[question favoriteCount] unsignedIntegerValue];
			for (int i = 0; i < count; ++i) { [counts addObject:[[question owner] userID]]; }
		}
		
		if (count == NSUIntegerMax) {
			count = [request fetchTotal];
		}
	}
	[request release];
	
	NSMutableArray * favoriteCounts = [NSMutableArray array];
	for (id user in counts) {
		[favoriteCounts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								   user, @"user",
								   [NSNumber numberWithUnsignedInteger:[counts countForObject:user]], @"count",
								   nil]];
	}
	[favoriteCounts sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"count" ascending:NO] autorelease]]];
	
	request = [[SKFetchRequest alloc] init];
	[request setEntity:[SKUser class]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"userID = %@", [favoriteCounts valueForKey:@"user"]]];
	
	NSArray * users = [site executeSynchronousFetchRequest:request];
	[request release];
	
	NSDictionary * userMapping = [NSDictionary dictionaryWithObjects:users forKeys:[users valueForKey:@"userID"]];
	
	for (NSDictionary * top in favoriteCounts) {
		SKUser * user = [userMapping objectForKey:[top objectForKey:@"user"]];
		NSLog(@"%02lu - %@ [%@]", [[top objectForKey:@"count"] unsignedIntegerValue], [user displayName], [user userID]);
	}
}

@end
