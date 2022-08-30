// 
// Copyright 2021 The Matrix.org Foundation C.I.C
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "MXLogObjcWrapper.h"
#import "GeneratedInterface-Swift.h"

@implementation MXLogObjcWrapper

+ (void)logVerbose:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line
{
    [MXLog logVerbose:message file:file function:function line:line];
}

+ (void)logDebug:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line
{
    [MXLog logDebug:message file:file function:function line:line];
}

+ (void)logInfo:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line
{
    [MXLog logInfo:message file:file function:function line:line];
}

+ (void)logWarning:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line
{
    [MXLog logWarning:message file:file function:function line:line];
}

+ (void)logError:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line context:(id)context
{
    [MXLog logError:message file:file function:function line:line context:context];
}

+ (void)logFailure:(NSString *)message file:(NSString *)file function:(NSString *)function line:(NSUInteger)line context:(id)context
{
    [MXLog logFailure:message file:file function:function line:line context:context];
}

@end
