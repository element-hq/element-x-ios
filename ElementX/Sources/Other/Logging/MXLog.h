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

#define MXLogVerbose(message, ...) { \
    [MXLogObjcWrapper logVerbose:[NSString stringWithFormat: message, ##__VA_ARGS__] file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__]; \
}

#define MXLogDebug(message, ...) { \
    [MXLogObjcWrapper logDebug:[NSString stringWithFormat: message, ##__VA_ARGS__] file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__]; \
}

#define MXLogInfo(message, ...) { \
    [MXLogObjcWrapper logInfo:[NSString stringWithFormat: message, ##__VA_ARGS__] file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__]; \
}

#define MXLogWarning(message, ...) { \
    [MXLogObjcWrapper logWarning:[NSString stringWithFormat: message, ##__VA_ARGS__] file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__]; \
}

#define MXLogError(message) { \
    [MXLogObjcWrapper logError:message file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__ context:nil]; \
}

#define MXLogErrorDetails(message, details) { \
    [MXLogObjcWrapper logError:message file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__ context:details]; \
}

#define MXLogFailure(message) { \
    [MXLogObjcWrapper logFailure:message file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__ context:nil]; \
}

#define MXLogFailureDetails(message, details) { \
    [MXLogObjcWrapper logFailure:message file:@__FILE__ function:[NSString stringWithFormat:@"%s", __FUNCTION__] line:__LINE__ context:details]; \
}
