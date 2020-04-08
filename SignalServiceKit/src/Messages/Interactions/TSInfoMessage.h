//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "OWSReadTracking.h"
#import "TSMessage.h"

NS_ASSUME_NONNULL_BEGIN

@class SignalServiceAddress;

@interface TSInfoMessage : TSMessage <OWSReadTracking>

typedef NS_ENUM(NSInteger, TSInfoMessageType) {
    TSInfoMessageTypeSessionDidEnd,
    TSInfoMessageUserNotRegistered,
    // TSInfoMessageTypeUnsupportedMessage appears to be obsolete.
    TSInfoMessageTypeUnsupportedMessage,
    TSInfoMessageTypeGroupUpdate,
    TSInfoMessageTypeGroupQuit,
    TSInfoMessageTypeDisappearingMessagesUpdate,
    TSInfoMessageAddToContactsOffer,
    TSInfoMessageVerificationStateChange,
    TSInfoMessageAddUserToProfileWhitelistOffer,
    TSInfoMessageAddGroupToProfileWhitelistOffer,
    TSInfoMessageUnknownProtocolVersion,
    TSInfoMessageUserJoinedSignal,
    TSInfoMessageSyncedThread
};


typedef NSString *InfoMessageUserInfoKey NS_STRING_ENUM;

extern InfoMessageUserInfoKey const InfoMessageUserInfoKeyOldGroupModel;
extern InfoMessageUserInfoKey const InfoMessageUserInfoKeyNewGroupModel;
extern InfoMessageUserInfoKey const InfoMessageUserInfoKeyOldDisappearingMessageToken;
extern InfoMessageUserInfoKey const InfoMessageUserInfoKeyNewDisappearingMessageToken;
extern InfoMessageUserInfoKey const InfoMessageUserInfoKeyGroupUpdateSourceAddress;

+ (instancetype)userNotRegisteredMessageInThread:(TSThread *)thread address:(SignalServiceAddress *)address;

@property (nonatomic, readonly) TSInfoMessageType messageType;
@property (nonatomic, readonly, nullable) NSString *customMessage;
@property (nonatomic, readonly, nullable) NSDictionary<InfoMessageUserInfoKey, id> *infoMessageUserInfo;
@property (nonatomic, readonly, nullable) SignalServiceAddress *unregisteredAddress;

- (instancetype)initMessageWithTimestamp:(uint64_t)timestamp
                                inThread:(TSThread *)thread
                             messageBody:(nullable NSString *)body
                           attachmentIds:(NSArray<NSString *> *)attachmentIds
                        expiresInSeconds:(uint32_t)expiresInSeconds
                         expireStartedAt:(uint64_t)expireStartedAt
                           quotedMessage:(nullable TSQuotedMessage *)quotedMessage
                            contactShare:(nullable OWSContact *)contactShare
                             linkPreview:(nullable OWSLinkPreview *)linkPreview
                          messageSticker:(nullable MessageSticker *)messageSticker
                       isViewOnceMessage:(BOOL)isViewOnceMessage NS_UNAVAILABLE;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
                   customMessage:(nullable NSString *)customMessage
             infoMessageUserInfo:(nullable NSDictionary<InfoMessageUserInfoKey, id> *)infoMessageUserInfo
                     messageType:(TSInfoMessageType)messageType
                            read:(BOOL)read
             unregisteredAddress:(nullable SignalServiceAddress *)unregisteredAddress
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:receivedAtTimestamp:sortId:timestamp:uniqueThreadId:attachmentIds:body:contactShare:expireStartedAt:expiresAt:expiresInSeconds:isViewOnceComplete:isViewOnceMessage:linkPreview:messageSticker:quotedMessage:storedShouldStartExpireTimer:customMessage:infoMessageUserInfo:messageType:read:unregisteredAddress:));

// clang-format on

// --- CODE GENERATION MARKER

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)contact
                      messageType:(TSInfoMessageType)infoMessage NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
                    customMessage:(NSString *)customMessage;

- (instancetype)initWithThread:(TSThread *)thread
                   messageType:(TSInfoMessageType)infoMessage
           infoMessageUserInfo:(NSDictionary<InfoMessageUserInfoKey, id> *)infoMessageUserInfo;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
              unregisteredAddress:(SignalServiceAddress *)unregisteredAddress;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageBody:(nullable NSString *)body
                    attachmentIds:(NSArray<NSString *> *)attachmentIds
                 expiresInSeconds:(uint32_t)expiresInSeconds
                  expireStartedAt:(uint64_t)expireStartedAt NS_UNAVAILABLE;

- (NSString *)systemMessageTextWithTransaction:(SDSAnyReadTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
