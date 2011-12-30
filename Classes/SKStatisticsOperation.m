//
//  SKStatisticsOperation.m
//  StackKit
//
//  Created by Dave DeLong on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SKStatisticsOperation.h"
#import "NSDictionary+SKAdditions.h"
#import "SKJSONParser.h"
#import "SKConstants.h"
#import "SKConstants_Internal.h"

#import "SKSiteStatistics.h"
#import "SKSiteStatistics+Private.h"

#import <dispatch/dispatch.h>

@implementation SKStatisticsOperation
@synthesize handler;

- (id) initWithSite:(SKSite *)baseSite completionHandler:(SKStatisticsHandler)aHandler {
    self = [super initWithSite:baseSite];
    if (self) {
        [self setHandler:aHandler];
    }
    return self;
}

- (void) main {
    
    NSDictionary * queryDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[[self site] apiKey], SKSiteAPIKey,
                                                                                [[self site] apiParameter], SKQuerySite, nil];
    
	NSString * statsPath = [NSString stringWithFormat:@"info?%@", [queryDictionary sk_queryString]];

	NSString * statsCall = [[NSString stringWithFormat:@"https://api.stackexchange.com/%@", SKAPIVersion] stringByAppendingPathComponent:statsPath];
	
	NSURL * statsURL = [NSURL URLWithString:statsCall];
	
	NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[statsURL absoluteURL]];
	NSURLResponse * response = nil;
	
    NSError *error = nil;
	NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	SKSiteStatistics *stats = nil;
    NSDictionary *responseDictionary = SKParseJSON(responseString);
    
	if ([responseDictionary isKindOfClass:[NSDictionary class]] && !error) {
        NSDictionary *dictionary = nil;
        NSArray *statsArray = [responseDictionary objectForKey:SKAPIItems];
        
        if([statsArray isKindOfClass:[NSArray class]]) {   
            dictionary = [statsArray objectAtIndex:0];
        }
        
        if(dictionary) {
            stats = [SKSiteStatistics statsForSite:[self site] withResponseDictionary:dictionary];
        }
    }
    
    SKStatisticsHandler h = [self handler];
    dispatch_async(dispatch_get_main_queue(), ^{
        h(stats);
    });
}

- (void)dealloc {
    [handler release];
    [super dealloc];
}

@end
