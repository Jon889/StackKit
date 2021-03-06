//
//  SKSiteManager.m
//  StackKit
//
//  Created by Alex Rozanski on 12/02/2011.
//  Copyright 2011 Alex Rozanski. All rights reserved.
//

#import "SKSiteManager.h"
#import "SKSiteManager+Private.h"

#import "SKSite.h"
#import "SKSite+Private.h"

#import "SKConstants.h"
#import "SKConstants_Internal.h"
#import "NSDictionary+SKAdditions.h"
#import "SKMacros.h"

#import "SKUser.h"
#import "SKAssociatedUserOperation.h"

#import "SKJSONParser.h"

@interface SKSiteManager ()

- (void)_performInitialSetup;
- (void)fetchSites;

- (NSString*)cachedSitesFilename;

- (NSArray *)cachedSites;
- (void)cacheSites:(NSArray *)sites;

@end

static id _manager = nil;

__attribute__((constructor)) void SKSiteManager_construct() {
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    _manager = NSAllocateObject([SKSiteManager class], 0, nil);
    [_manager _performInitialSetup];
    [p drain];
}

__attribute__((destructor)) void SKSiteManager_destruct() {
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    [_manager release], _manager = nil;
    [p drain];
}

@implementation SKSiteManager

+ (id) sharedManager
{
    return [[_manager retain] autorelease];
}

#pragma mark -
#pragma mark Init/Dealloc

- (void)_performInitialSetup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _knownSitesQueue = dispatch_queue_create("com.stackkit.sites", 0);
        _knownSites = [[NSMutableArray alloc] init];
        stackAuthQueue = [[NSOperationQueue alloc] init];
        [stackAuthQueue setMaxConcurrentOperationCount:1];
        
        dispatch_async(_knownSitesQueue, ^{
            [self fetchSites];
        });
    });
}

+ (id) allocWithZone:(NSZone *)zone {
    SKLog(@"you may not allocate an SKSiteManager object");
    return nil;
}

- (void)dealloc {
    dispatch_release(_knownSitesQueue), _knownSitesQueue = nil;
    [_knownSites release], _knownSites = nil;
    [stackAuthQueue cancelAllOperations];
    [stackAuthQueue release], stackAuthQueue = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Loading

- (void)fetchSites {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sites = [self cachedSites];
    
    if(!sites) {
        BOOL hasMore = YES;
        NSMutableArray *allItems = [NSMutableArray array];
        NSUInteger currentPage = 1;
        NSUInteger lastCount = NSUIntegerMax;
        
        while (hasMore) {
            NSMutableDictionary *query = [NSMutableDictionary dictionary];
            [query setObject:[NSNumber numberWithUnsignedInteger:currentPage] forKey:SKQueryPage];
            [query setObject:[NSNumber numberWithUnsignedInteger:SKPageSizeLimitMax] forKey:SKQueryPageSize];

            NSString *url = [NSString stringWithFormat:@"https://api.stackexchange.com/%@/sites?%@", SKAPIVersion, [query sk_queryString]];
            
            NSURL *requestURL = [NSURL URLWithString:url];
            NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
            
            NSURLResponse * response = nil;
            NSError * connectionError = nil;
            NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
            
            NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            NSDictionary * responseObjects = SKParseJSON(responseString);
            if ([responseObjects isKindOfClass:[NSDictionary class]] == NO) {
                allItems = nil;
                break;
            }
            if ([responseObjects objectForKey:@"error_id"]) {//need to const these
                SKLog(@"Error fetching sites ID:%i Name:%@ Description:%@", [responseObjects objectForKey:@"error_id"], [responseObjects objectForKey:@"error_name"], [responseObjects objectForKey:@"description"]);
                break;
            }

            NSArray *items = [responseObjects objectForKey:SKAPIItems];
            [allItems addObjectsFromArray:items];
            
            //break is has_more is false;
            if ([[responseObjects objectForKey:@"has_more"] boolValue] == NO) {
                hasMore = NO;//this is a failsafe, I really don't want to be responsible for "DDoS attack" on API
                break;
            }
            
            //also break if we didn't get any objects on this loop
            NSUInteger currentCount = [allItems count];
            if (currentCount == lastCount) {
                break;
            }
            
            lastCount = [allItems count];
            currentPage++;
        }
        
        [self cacheSites:allItems];
        sites = allItems;
    }
    
    if(sites) {
        for (NSDictionary * siteDictionary in sites) {
            SKSite *thisSite = NSAllocateObject([SKSite class], 0, NULL);
            [thisSite mergeInformationFromDictionary:siteDictionary];
            [_knownSites addObject:thisSite];
            [thisSite release];
        }
    }
	[pool drain];
}

#pragma mark -
#pragma mark Sites

- (NSArray*) knownSites
{
    __block NSArray *sites = nil;
    dispatch_sync(_knownSitesQueue, ^{
        sites = [_knownSites copy]; 
    });
    
    return [sites autorelease]; 
}  

- (SKSite*) siteWithAPIParameter:(NSString *)aParameter
{
    NSArray *knownSites = [self knownSites];
    
    for (SKSite * aSite in knownSites) {
        if ([aSite.apiParameter isEqualToString:aParameter]) {
            return aSite;
        }
    }
    
    return nil;
}

- (SKSite *) siteWithName:(NSString *)name {
    NSArray *knownSites = [self knownSites];
    
    for (SKSite * aSite in knownSites) {
        if ([[aSite name] isEqualToString:name]) {
            return aSite;
        }
    }
    
    return nil;
}

- (SKSite*) stackOverflowSite {
    return [self siteWithAPIParameter:@"stackoverflow"];
}

- (SKSite*) metaStackOverflowSite {
    return [self siteWithAPIParameter:@"meta.stackoverflow"];
}

- (SKSite*) stackAppsSite {
    return [self siteWithAPIParameter:@"stackapps"];
}

- (SKSite*) serverFaultSite {
    return [self siteWithAPIParameter:@"serverfault"];
}

- (SKSite*) superUserSite {
    return [self siteWithAPIParameter:@"superuser"];
}

#pragma mark -
#pragma mark Site Counterparts

- (SKSite*) mainSiteForSite:(SKSite *)aSite
{
    NSString * host = [[aSite siteURL] host];
	NSArray * originalHostComponents = [host componentsSeparatedByString:@"."];
	if ([originalHostComponents containsObject:@"meta"] == NO) { return aSite; }
	
	NSMutableArray * newHostComponents = [originalHostComponents mutableCopy];
	[newHostComponents removeObject:@"meta"];
	
	NSString * qaHost = [newHostComponents componentsJoinedByString:@"."];
	[newHostComponents release];
	
	for (SKSite * potentialSite in [self knownSites]) {
		if ([[[potentialSite siteURL] host] isEqual:qaHost]) {
			return potentialSite;
		}		
	}
	return nil;
}

- (SKSite*) metaSiteForSite:(SKSite *)aSite
{
    //takes an API URL (api.somesite.com) and transforms it into (api.meta.somesite.com)
	//and then looks for a known site that has the same hostname
	
	NSString * host = [[aSite siteURL] host];
	
	NSArray * originalHostComponents = [host componentsSeparatedByString:@"."];
	//if we are a meta site, return ourself
	if ([originalHostComponents containsObject:@"meta"]) { return aSite; }
	
	NSMutableArray * newHostComponents = [originalHostComponents mutableCopy];
	if ([[newHostComponents objectAtIndex:0] isEqual:@"api"]) {
		[newHostComponents insertObject:@"meta" atIndex:1];
	} else {
		[newHostComponents insertObject:@"meta" atIndex:0];
	}
	NSString * metaHost = [newHostComponents componentsJoinedByString:@"."];
	[newHostComponents release];
	
	for (SKSite * potentialSite in [self knownSites]) {
		if ([[[potentialSite siteURL] host] isEqual:metaHost]) {
			return potentialSite;
		}
	}
	
	return nil;
}

- (SKSite*) companionSiteForSite:(SKSite *)aSite
{
    //if this is a meta site, return the QA site (and vice versa)
	if ([[[aSite siteURL] host] rangeOfString:@".meta."].location != NSNotFound) {
		return [self mainSiteForSite:aSite];
	} else {
		return [self metaSiteForSite:aSite];
	}
}

#pragma mark -
#pragma mark Persistence

- (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
#ifdef StackKitMac
    // alter basePath to point at the App's specific support dir, and not ~/Library/App Support
#endif
    
    NSString *asd = [basePath stringByAppendingPathComponent:@"StackKit"];
    
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:asd isDirectory:&isDir] == NO || isDir == NO) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:asd withIntermediateDirectories:YES attributes:nil error:&error]) {   
            SKLog(@"Error creating application support directory at %@ : %@", asd, error);
        }
    }
    
    return asd;
}

- (NSString*)cachedSitesFilename
{
    return [[self applicationSupportDirectory] stringByAppendingPathComponent:@"sites.db"];
}

- (NSArray *)cachedSites
{
    //Only re-request the dictionary if it is older than a day (following SO API guidelines)
    NSDictionary *cacheDictionary = [NSDictionary dictionaryWithContentsOfFile:[self cachedSitesFilename]];
    NSDate *cacheDate = [cacheDictionary objectForKey:@"cacheDate"];
    
    NSDateComponents * oneDay = [[NSDateComponents alloc] init];
    [oneDay setDay:1];
    
    NSDate *cacheInvalidationDate = [[NSCalendar currentCalendar] dateByAddingComponents:oneDay toDate:cacheDate options:0];
    [oneDay release];
    
    //Return nil if the cache is out of date
    if ([[cacheInvalidationDate laterDate:cacheDate] isEqualToDate:cacheInvalidationDate]) {
        return nil;
    }
    
    return [cacheDictionary objectForKey:@"sites"];
}

- (void)cacheSites:(NSArray *)sites
{
    NSMutableDictionary *cacheDictionary = [NSMutableDictionary dictionary];
    [cacheDictionary setObject:sites forKey:@"sites"];
    [cacheDictionary setObject:[NSDate date] forKey:@"cacheDate"];
     
    [cacheDictionary writeToFile:[self cachedSitesFilename] atomically:NO];
}

#pragma mark -
#pragma mark Associated Users

- (void) requestAssociatedUsersForUser:(SKUser *)user completionHandler:(SKRequestHandler)handler {
    if (user == nil) { return; }
    if (handler == nil) { return; }
    
    SKAssociatedUserOperation *op = [[SKAssociatedUserOperation alloc] initWithUser:user handler:handler];
    if (op == nil) { return; }
    
    [stackAuthQueue addOperation:op];
    [op release];
}

@end
