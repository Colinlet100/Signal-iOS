//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "OWSReaction.h"
#import "SignalServiceKit/SignalServiceKit-Swift.h"

@interface OWSReaction ()

@property (nonatomic, readonly, nullable) NSString *reactorE164;
@property (nonatomic, readonly, nullable) NSString *reactorUUID;

@end

@implementation OWSReaction

- (instancetype)initWithUniqueMessageId:(NSString *)uniqueMessageId emoji:(NSString *)emoji reactor:(SignalServiceAddress *)reactor sentAtTimestamp:(uint64_t)sentAtTimestamp receivedAtTimestamp:(uint64_t)receivedAtTimestamp
{
    if (self = [super init]) {
        _uniqueMessageId = uniqueMessageId;
        _emoji = emoji;
        _reactorUUID = reactor.uuidString;
        _reactorE164 = reactor.phoneNumber;
        _sentAtTimestamp = sentAtTimestamp;
        _receivedAtTimestamp = receivedAtTimestamp;
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
                           emoji:(NSString *)emoji
                     reactorE164:(nullable NSString *)reactorE164
                     reactorUUID:(nullable NSString *)reactorUUID
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                 sentAtTimestamp:(uint64_t)sentAtTimestamp
                 uniqueMessageId:(NSString *)uniqueMessageId
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _emoji = emoji;
    _reactorE164 = reactorE164;
    _reactorUUID = reactorUUID;
    _receivedAtTimestamp = receivedAtTimestamp;
    _sentAtTimestamp = sentAtTimestamp;
    _uniqueMessageId = uniqueMessageId;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

#pragma mark -

- (SignalServiceAddress *)reactor
{
    return [[SignalServiceAddress alloc] initWithUuidString:self.reactorUUID phoneNumber:self.reactorE164];
}

@end
