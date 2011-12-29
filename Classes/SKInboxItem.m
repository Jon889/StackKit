//
//  SKInboxItem.m
//  StackKit
//
//  Created by Jonathan Bailey on 29/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SKInboxItem.h"
#import "SKObject+Private.h"
#import "SKConstants_Internal.h"

#import "SKDefinitions.h"
#import "SKMacros.h"
#import "SKConstants.h"


// used internally
NSString * const SKInboxResponseTypeComment = @"comment";
NSString * const SKInboxResponseTypeChatMessage = @"chat_message";
NSString * const SKInboxResponseTypeNewAnswer = @"new_answer";
NSString * const SKInboxResponseTypeCareersMessage = @"careers_message";
NSString * const SKInboxResponseTypeCareersInvitations = @"careers_invitations";
NSString * const SKInboxResponseTypeMetaQuestion = @"meta_question";

@implementation SKInboxItem

SK_GETTER(NSNumber *, type);
SK_GETTER(NSNumber *, questionID);
SK_GETTER(NSNumber *, answerID);
SK_GETTER(NSNumber *, commentID);
SK_GETTER(NSString *, title);
SK_GETTER(NSDate *, creationDate);
SK_GETTER(NSNumber *, readState);
SK_GETTER(NSString *, body);
SK_GETTER(NSURL *, linkURL);

+ (NSDictionary *) APIAttributeToPropertyMapping {
    static NSDictionary *mapping = nil;
    if (!mapping) {
        mapping = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"type", SKAPIItem_Type,
                   @"questionID", SKAPIQuestion_ID,
                   @"answerID", SKAPIAnswer_ID,
                   @"commentID", SKAPIComment_ID,
                   @"title", SKAPITitle,
                   @"creationDate", SKAPICreation_Date,
                   @"readState", SKAPIIs_Unread,
                   @"body", SKAPIBody,
                   @"linkURL", SKAPILink,
                   nil];
    }
    return mapping;
}

- (SKFetchRequest *) mergeRequest {
    SKFetchRequest *r = [[SKFetchRequest alloc] init];
    [r setEntity:[SKInboxItem class]];
    [r setPredicate:[NSPredicate predicateWithFormat:@"linkURL = %@", [self linkURL]]];
    
    return [r autorelease];
}

+ (NSString *)apiResponseUniqueIDKey {
    return @"link";
}

+ (NSString *) apiResponseDataKey {
    return @"items";
}
- (id) transformValueToMerge:(id)value forProperty:(NSString *)property {
    if ([property isEqualToString:@"type"]) {
        
		SKInboxItemType_t type = SKInboxItemTypeComment;
		if ([value isEqual:SKInboxResponseTypeChatMessage]) {
			type = SKInboxItemTypeChatMessage;
		} else if ([value isEqual:SKInboxResponseTypeNewAnswer]) {
			type = SKInboxItemTypeNewAnswer;
		} else if ([value isEqual:SKInboxResponseTypeCareersMessage]) {
			type = SKInboxItemTypeCareersMessage;
		} else if ([value isEqual:SKInboxResponseTypeCareersInvitations]) {
			type = SKInboxItemTypeCareersInvitations;
		} else if ([value isEqual:SKInboxResponseTypeMetaQuestion]) {
			type = SKInboxItemTypeMetaQuestion;
		}
        return [NSNumber numberWithInt:type];
    } 
    if ([property isEqualToString:@"readState"]) {
        SKInboxItemState_t state = SKInboxItemStateRead;
        if ([value boolValue] == YES) {
            state = SKInboxItemStateUnread;
        }
        return [NSNumber numberWithInt:state];
    }
    
    // super will convert dates and URLs for us
    return [super transformValueToMerge:value forProperty:property];
}
- (id)transformValueToMerge:(id)value forRelationship:(NSString *)relationship {
    // override for the sake of completeness
    return [super transformValueToMerge:value forRelationship:relationship];
}
@end
