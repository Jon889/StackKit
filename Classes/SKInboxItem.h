//
//  SKInboxItem.h
//  StackKit
//
//  Created by Jonathan Bailey on 29/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "SKObject.h"

@interface SKInboxItem : SKObject
{
}
@property (nonatomic, readonly) NSNumber *type;
@property (nonatomic, readonly) NSNumber *questionID;
@property (nonatomic, readonly) NSNumber *answerID;
@property (nonatomic, readonly) NSNumber *commentID;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSNumber *readState;
@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) NSURL *linkURL;

@end
