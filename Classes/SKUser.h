//
//  SKUser.h
//  StackKit
//
//  Created by Dave DeLong on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "SKObject.h"

@interface SKUser : SKObject  
{
}

@property (nonatomic, readonly) NSString * aboutMe; //Not in Default Filter
@property (nonatomic, readonly) NSNumber * acceptRate;//removed?
@property (nonatomic, readonly) NSNumber * age;
@property (nonatomic, readonly) NSNumber * accountID;
@property (nonatomic, readonly) NSDate * creationDate;
@property (nonatomic, readonly) NSString * displayName;
@property (nonatomic, readonly) NSNumber * downVotes; //Not in Default Filter
@property (nonatomic, readonly) NSDate * lastAccessDate;
@property (nonatomic, readonly) NSString * location;
@property (nonatomic, readonly) NSNumber * reputation;
@property (nonatomic, readonly) NSNumber * upVotes; //Not in Default Filter
@property (nonatomic, readonly) NSNumber * userID;
@property (nonatomic, readonly) NSNumber * userType;
@property (nonatomic, readonly) NSNumber * viewCount; //Not in Default Filter
@property (nonatomic, readonly) NSNumber * answerCount; //Not in Default Filter
@property (nonatomic, readonly) NSNumber * questionCount; //Not in Default Filter
@property (nonatomic, readonly) NSURL * websiteURL;

//2.0 properties
@property (nonatomic, readonly) NSURL * profileImageURL;
@property (nonatomic, readonly) NSNumber *reputationChangeDay;
@property (nonatomic, readonly) NSNumber *reputationChangeWeek;
@property (nonatomic, readonly) NSNumber *reputationChangeMonth;
@property (nonatomic, readonly) NSNumber *reputationChangeQuarter;
@property (nonatomic, readonly) NSNumber *reputationChangeYear;

@property (nonatomic, readonly) NSDate * lastModifiedDate;
@property (nonatomic, readonly) NSNumber * isEmployee; //BOOL
@property (nonatomic, readonly) NSURL * link;
@property (nonatomic, readonly) NSDate * timedPenaltyDate;
@property (nonatomic, readonly) NSNumber *goldBadgeCount;
@property (nonatomic, readonly) NSNumber *silverBadgeCount;
@property (nonatomic, readonly) NSNumber *bronzeBadgeCount;


@property (nonatomic, readonly) NSSet * awardedBadges;
@property (nonatomic, readonly) NSSet * directedComments;
@property (nonatomic, readonly) NSSet * posts;
@property (nonatomic, readonly) NSSet * favoritedQuestions;

@property (nonatomic, readonly) NSURL * gravatarIconURL;

@property (nonatomic, readonly) NSSet * questions;
@property (nonatomic, readonly) NSSet * answers;
@property (nonatomic, readonly) NSSet * comments;

- (NSURL *) gravatarIconURLForSize:(CGSize)size;

@end

