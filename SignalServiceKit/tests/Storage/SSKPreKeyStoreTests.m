//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

#import "SDSDatabaseStorage+Objc.h"
#import "SSKBaseTestObjC.h"
#import "SSKPreKeyStore.h"
#import "SignedPrekeyRecord.h"
#import <SignalServiceKit/OWSIdentityManager.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

@interface SSKPreKeyStoreTests : SSKBaseTestObjC

@end

#pragma mark -

@interface SSKPreKeyStore (Tests)

@end

#pragma mark -

@implementation SSKPreKeyStore (Tests)

- (nullable PreKeyRecord *)loadPreKey:(int)preKeyId
{
    __block PreKeyRecord *_Nullable result;
    [self.databaseStorage readWithBlock:^(SDSAnyReadTransaction *transaction) {
        result = [self loadPreKey:preKeyId transaction:transaction];
    }];
    return result;
}

@end

#pragma mark -

@implementation SSKPreKeyStoreTests

- (SSKPreKeyStore *)preKeyStore
{
    return [self signalProtocolStoreForIdentity:OWSIdentityACI].preKeyStore;
}

- (void)testGeneratingAndStoringPreKeys
{
    NSArray *generatedKeys = [self.preKeyStore generatePreKeyRecords];

    XCTAssert([generatedKeys count] == 100, @"Not hundred keys generated");

    [self.preKeyStore storePreKeyRecords:generatedKeys];

    PreKeyRecord *lastPreKeyRecord = [generatedKeys lastObject];
    PreKeyRecord *firstPreKeyRecord = [generatedKeys firstObject];

    XCTAssert([[self.preKeyStore loadPreKey:lastPreKeyRecord.Id].keyPair.publicKey
        isEqualToData:lastPreKeyRecord.keyPair.publicKey]);

    XCTAssert([[self.preKeyStore loadPreKey:firstPreKeyRecord.Id].keyPair.publicKey
        isEqualToData:firstPreKeyRecord.keyPair.publicKey]);

    SSKPreKeyStore *pniStore = [self signalProtocolStoreForIdentity:OWSIdentityPNI].preKeyStore;
    XCTAssertNil([pniStore loadPreKey:firstPreKeyRecord.Id]);
}

- (void)testRemovingPreKeys
{
    NSArray *generatedKeys = [self.preKeyStore generatePreKeyRecords];

    XCTAssert([generatedKeys count] == 100, @"Not hundred keys generated");

    [self.preKeyStore storePreKeyRecords:generatedKeys];

    PreKeyRecord *lastPreKeyRecord = [generatedKeys lastObject];
    PreKeyRecord *firstPreKeyRecord = [generatedKeys firstObject];

    SSKPreKeyStore *pniStore = [self signalProtocolStoreForIdentity:OWSIdentityPNI].preKeyStore;
    [pniStore storePreKeyRecords:generatedKeys];

    [self writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
        [self.preKeyStore removePreKey:lastPreKeyRecord.Id transaction:transaction];
    }];

    XCTAssertNil([self.preKeyStore loadPreKey:lastPreKeyRecord.Id]);
    XCTAssertNotNil([self.preKeyStore loadPreKey:firstPreKeyRecord.Id]);
    XCTAssertNotNil([pniStore loadPreKey:firstPreKeyRecord.Id]);
    XCTAssertNotNil([pniStore loadPreKey:firstPreKeyRecord.Id]);
}

@end
