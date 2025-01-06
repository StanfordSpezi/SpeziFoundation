//
//  ObjCExceptionHandling.h
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-25.
//

#ifndef ObjCExceptionHandling_h
#define ObjCExceptionHandling_h

#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>

NS_ASSUME_NONNULL_BEGIN

NSException *_Nullable InvokeBlockCatchingNSExceptionIfThrown(NS_NOESCAPE void(^block)(void));

NS_ASSUME_NONNULL_END

#endif /* ObjCExceptionHandling_h */
