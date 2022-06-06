/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2020 The Matrix.org Foundation C.I.C

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

/**
 The `MXLogger` tool redirects NSLog output into a fixed pool of files.
 Another log file is used every time [MXLogger redirectNSLogToFiles:YES]
 is called. The pool contains 3 files.
 
 `MXLogger` can track and log uncatched exceptions or crashes.
 */
@interface MXLogger : NSObject

/**
 Redirect NSLog output to MXLogger files.
 
 It is advised to condition this redirection in '#if (!isatty(STDERR_FILENO))' block to enable
 it only when the device is not attached to the debugger.

 @param redirectNSLogToFiles YES to enable the redirection.
 */
+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles;

/**
 Redirect NSLog output to MXLogger files.
 
 It is advised to condition this redirection in '#if (!isatty(STDERR_FILENO))' block to enable
 it only when the device is not attached to the debugger.
 
 @param redirectNSLogToFiles YES to enable the redirection.
 @param numberOfFiles number of files to keep (default is 10).
 */
+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles numberOfFiles:(NSUInteger)numberOfFiles;

/**
 Redirect NSLog output to MXLogger files.
 
 @param redirectNSLogToFiles YES to enable the redirection.
 @param numberOfFiles number of files to keep (default is 10).
 @param sizeLimit size limit of log files in bytes. 0 means no limitation, the default value for other methods
 */
+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles numberOfFiles:(NSUInteger)numberOfFiles sizeLimit:(NSUInteger)sizeLimit;

/**
 Delete all log files.
 */
+ (void)deleteLogFiles;

/**
 Get the list of all log files.
 
 @return files of
 */
+ (NSArray<NSString*>*)logFiles;

/**
 Make `MXLogger` catch and log unmanaged exceptions or application crashes.

 When such error happens, `MXLogger` stores the application stack trace into a file
 just before the application leaves. The path of this file is provided by [MXLogger crashLog].
 
 @param logCrashes YES to enable the catch.
 */
+ (void)logCrashes:(BOOL)logCrashes;

/**
 Set the app build version.
 It will be reported in crash report.
 */
+ (void)setBuildVersion:(NSString*)buildVersion;

/**
 Set a sub name for namespacing log files.

 A sub name must be set when running from an app extension because extensions can
 run in parallel to the app.
 It must be called before `redirectNSLogToFiles`.

 @param subLogName the subname for log files. Files will be named as 'console-[subLogName].log'
        Default is nil.
 */
+ (void)setSubLogName:(NSString*)subLogName;

/**
 If any, get the file containing the last application crash log.
 
 Only one crash log is stored at a time. The best moment for the app to handle it is the 
 at its next startup.
 
 @return the crash log file. nil if there is none.
 */
+ (NSString*)crashLog;

/**
 Delete the crash log file.
 */
+ (void)deleteCrashLog;

@end
