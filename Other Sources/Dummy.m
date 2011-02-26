//
//  Dummy.m
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

#import <Foundation/Foundation.h>
#import <StackKit/StackKit.h>
#import "SKJSONParser.h"

int main(int argc, char* argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString *test = [NSString stringWithContentsOfFile:@"/Users/dave/Desktop/test.json" encoding:NSUTF8StringEncoding error:nil];
    id value = SKParseJSON(test);
    NSLog(@"%@", value);
    
    SKFetchRequest *request = [[SKFetchRequest alloc] init];
    [request setEntity:[SKQuestion class]];
    [request setFetchLimit:25];
    NSArray *results = [[[SKSiteManager sharedManager] stackOverflowSite] executeSynchronousFetchRequest:request];

    NSLog(@"%@", results);
	
//	SKSite * s = [[SKSiteManager sharedManager] stackOverflowSite];
//	SKFetchRequest * r = [[SKFetchRequest alloc] init];
//	[r setEntity:[SKUser class]];
//	[r setPredicate:[NSPredicate predicateWithFormat:@"userID = %d", 115730]];
//
//    NSArray *users = [s executeSynchronousFetchRequest:r];
//    [r release];
//    
//    SKUser *davedelong = [users objectAtIndex:0];
//    
//    NSLog(@"%@", davedelong);
//    
//    r = [[SKFetchRequest alloc] init];
//    [r setEntity:[SKQuestion class]];
//    [r setPredicate:[NSPredicate predicateWithFormat:@"owner = %@", davedelong]];
//    
//    NSArray *questions = [s executeSynchronousFetchRequest:r];
//    [r release];
//    
//    NSLog(@"%@", questions);
//	
//	[r release];
	
	[pool drain];
	return 0;
}