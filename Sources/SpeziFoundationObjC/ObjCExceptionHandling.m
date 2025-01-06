//
//  ObjCExceptionHandling.m
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-25.
//

#import "ObjCExceptionHandling.h"

NSException *_Nullable InvokeBlockCatchingNSExceptionIfThrown(NS_NOESCAPE void(^block)(void)) {
    @try {
        block();
        return nil;
    } @catch (NSException *exception) {
        return exception;
    }
}
