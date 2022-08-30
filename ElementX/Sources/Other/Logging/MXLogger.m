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

#import "MXLogger.h"
#import "MXLog.h"
#import "GeneratedInterface-Swift.h"

// stderr so it can be restored
int stderrSave = 0;

static NSString *buildVersion;
static NSString *subLogName;

#define MXLOGGER_CRASH_LOG @"crash.log"

@implementation MXLogger

#pragma mark - NSLog redirection
+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles
{
    [self redirectNSLogToFiles:redirectNSLogToFiles numberOfFiles:10];
}

+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles numberOfFiles:(NSUInteger)numberOfFiles
{
    [self redirectNSLogToFiles:redirectNSLogToFiles numberOfFiles:numberOfFiles sizeLimit:0];
}

+ (void)redirectNSLogToFiles:(BOOL)redirectNSLogToFiles numberOfFiles:(NSUInteger)numberOfFiles sizeLimit:(NSUInteger)sizeLimit
{
    if (redirectNSLogToFiles)
    {
        NSMutableString *log = [NSMutableString string];

        // Default subname
        if (!subLogName)
        {
            subLogName = @"";
        }

        // Set log location
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsFolderPath = [MXLogger logsFolderPath];

        // Do a circular buffer based on X files
        for (NSInteger index = numberOfFiles - 2; index >= 0; index--)
        {
            NSString *nsLogPathOlder;
            NSString *nsLogPathCurrent;

            if (index == 0)
            {
                nsLogPathOlder   = [NSString stringWithFormat:@"console%@.1.log", subLogName];
                nsLogPathCurrent = [NSString stringWithFormat:@"console%@.log", subLogName];
            }
            else
            {
                nsLogPathOlder   = [NSString stringWithFormat:@"console%@.%tu.log", subLogName, index + 1];
                nsLogPathCurrent = [NSString stringWithFormat:@"console%@.%tu.log", subLogName, index];
            }

            nsLogPathOlder = [logsFolderPath stringByAppendingPathComponent:nsLogPathOlder];
            nsLogPathCurrent = [logsFolderPath stringByAppendingPathComponent:nsLogPathCurrent];

            if ([fileManager fileExistsAtPath:nsLogPathCurrent])
            {
                if ([fileManager fileExistsAtPath:nsLogPathOlder])
                {
                    // Temp log
                    [log appendFormat:@"removeItemAtPath: %@\n", nsLogPathOlder];

                    NSError *error;
                    [fileManager removeItemAtPath:nsLogPathOlder error:&error];
                    if (error)
                    {
                        [log appendFormat:@"removeItemAtPath: %@. Error: %@\n", nsLogPathOlder, error];
                    }
                }

                // Temp log
                [log appendFormat:@"moveItemAtPath: %@ toPath: %@\n", nsLogPathCurrent, nsLogPathOlder];

                NSError *error;
                [fileManager moveItemAtPath:nsLogPathCurrent toPath:nsLogPathOlder error:&error];
                if (error)
                {
                    [log appendFormat:@"moveItemAtPath: %@ toPath: %@. Error: %@\n", nsLogPathCurrent, nsLogPathOlder, error];
                }
            }
        }

        // Save stderr so it can be restored.
        stderrSave = dup(STDERR_FILENO);

        NSString *nsLogPath = [logsFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"console%@.log", subLogName]];
        freopen([nsLogPath fileSystemRepresentation], "w+", stderr);

        MXLogDebug(@"redirectNSLogToFiles: YES");
        if (log.length)
        {
            // We can now log into files
            MXLogDebug(@"%@", log);
        }
        
        [self removeExtraFilesFromCount:numberOfFiles];
        
        if (sizeLimit > 0)
        {
            [self removeFilesAfterSizeLimit:sizeLimit];
        }
    }
    else if (stderrSave)
    {
        // Flush before restoring stderr
        fflush(stderr);

        // Now restore stderr, so new output goes to console.
        dup2(stderrSave, STDERR_FILENO);
        close(stderrSave);
    }
}

+ (void)deleteLogFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *logFile in [self logFiles])
    {
        [fileManager removeItemAtPath:logFile error:nil];
    }
}

+ (NSArray<NSString*>*)logFiles
{
    NSMutableArray *logFiles = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logsFolderPath = [MXLogger logsFolderPath];

    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:logsFolderPath];

    // Find all *.log files
    NSString *file = nil;
    while ((file = [dirEnum nextObject]))
    {
        if ([[file lastPathComponent] hasPrefix:@"console"])
        {
            NSString *logPath = [logsFolderPath stringByAppendingPathComponent:file];
            [logFiles addObject:logPath];
        }
    }

    MXLogDebug(@"logFiles: %@", logFiles);

    return logFiles;
}


#pragma mark - Exceptions and crashes
// Exceptions uncaught by try catch block are handled here
static void handleUncaughtException(NSException *exception)
{
    [MXLogger logCrashes:NO];

    // Extract running app information
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* appVersion;
    NSString* app, *appId;

    app = infoDict[@"CFBundleExecutable"];
    appId = infoDict[@"CFBundleIdentifier"];

    if ([infoDict objectForKey:@"CFBundleVersion"])
    {
        appVersion =  [NSString stringWithFormat:@"%@ (r%@)", [infoDict objectForKey:@"CFBundleShortVersionString"],  [infoDict objectForKey:@"CFBundleVersion"]];
    }
    else
    {
        appVersion =  [infoDict objectForKey:@"CFBundleShortVersionString"];
    }

    // Build the crash log
#if TARGET_OS_IPHONE
    NSString *model = [[UIDevice currentDevice] model];
    NSString *version = [[UIDevice currentDevice] systemVersion];
#elif TARGET_OS_OSX
    NSString *model = @"Mac";
    NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
    NSArray  *backtrace = [exception callStackSymbols];
    NSString *description = [NSString stringWithFormat:@"%.0f - %@\n%@\nApplication: %@ (%@)\nApplication version: %@\nBuild: %@\n%@ %@\n\nMain thread: %@\n%@\n",
                             [[NSDate date] timeIntervalSince1970],
                             [NSDate date],
                             exception.description,
                             app, appId,
                             appVersion,
                             buildVersion,
                             model, version,
                             [NSThread isMainThread] ? @"YES" : @"NO",
                             backtrace];

    // Write to the crash log file
    [MXLogger deleteCrashLog];
    NSString *crashLog = crashLogPath();
    [description writeToFile:crashLog
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];

    MXLogErrorDetails(@"handleUncaughtException", @{
        @"description": description ?: @"unknown"
    });
}

// Signals emitted by the app are handled here
static void handleSignal(int signalValue)
{
    // Throw a custom Objective-C exception
    // The Objective-C runtime will then be able to build a readable call stack in handleUncaughtException
    [NSException raise:@"Signal detected" format:@"Signal detected: %d", signalValue];
}

+ (void)logCrashes:(BOOL)logCrashes
{
    if (logCrashes)
    {
        // Handle not managed exceptions by ourselves
        NSSetUncaughtExceptionHandler(&handleUncaughtException);

        // Register signal event (seg fault & cie)
        signal(SIGABRT, handleSignal);
        signal(SIGILL, handleSignal);
        signal(SIGSEGV, handleSignal);
        signal(SIGFPE, handleSignal);
        signal(SIGBUS, handleSignal);
    }
    else
    {
        // Disable crash handling
        NSSetUncaughtExceptionHandler(NULL);
        signal(SIGABRT, SIG_DFL);
        signal(SIGILL, SIG_DFL);
        signal(SIGSEGV, SIG_DFL);
        signal(SIGFPE, SIG_DFL);
        signal(SIGBUS, SIG_DFL);
    }
}

+ (void)setBuildVersion:(NSString *)theBuildVersion
{
    buildVersion = theBuildVersion;
}

+ (void)setSubLogName:(NSString *)theSubLogName
{
    subLogName = [NSString stringWithFormat:@"-%@", theSubLogName];
}

// Return the path of the crash log file
static NSString* crashLogPath(void)
{
    return [[MXLogger logsFolderPath] stringByAppendingPathComponent:MXLOGGER_CRASH_LOG];
}

+ (NSString*)crashLog
{
    NSString *exceptionLog;

    NSString *crashLog = crashLogPath();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:crashLog])
    {
        exceptionLog = crashLog;
    }
    return exceptionLog;
}

+ (void)deleteCrashLog
{
    NSString *crashLog = crashLogPath();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:crashLog])
    {
        [fileManager removeItemAtPath:crashLog error:nil];
    }
}

// The folder where logs are stored
+ (NSString*)logsFolderPath
{
    NSString *logsFolderPath = nil;

    NSURL *sharedContainerURL = [[NSFileManager defaultManager] appGroupContainerURL];
    if (sharedContainerURL)
    {
        logsFolderPath = [sharedContainerURL path];
    }
    else
    {
        NSArray<NSURL *> *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        logsFolderPath = paths[0].path;
    }

    return logsFolderPath;
}


// If [self redirectNSLogToFiles: numberOfFiles:] is called with a lower numberOfFiles we need to do some cleanup
+ (void)removeExtraFilesFromCount:(NSUInteger)count
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logsFolderPath = [MXLogger logsFolderPath];
    
    NSUInteger index = count;
    do
    {
        NSString *fileName = [NSString stringWithFormat:@"console%@.%tu.log", subLogName, index];
        NSString *logFile = [logsFolderPath stringByAppendingPathComponent:fileName];
        
        if ([fileManager fileExistsAtPath:logFile])
        {
            [fileManager removeItemAtPath:logFile error:nil];
            MXLogDebug(@"removeExtraFilesFromCount: %@. removeItemAtPath: %@\n", @(count), logFile);
        }
        else
        {
            break;
        }
    }
    while (index++);
}

+ (void)removeFilesAfterSizeLimit:(NSUInteger)sizeLimit
{
    NSUInteger logSize = 0;
    BOOL removeFiles = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logsFolderPath = [MXLogger logsFolderPath];
    
    // Start from console.1.log. Do not consider console.log. It should be almost empty
    NSUInteger index = 0;
    while (++index)
    {
        NSString *fileName = [NSString stringWithFormat:@"console%@.%tu.log", subLogName, index];
        NSString *logFile = [logsFolderPath stringByAppendingPathComponent:fileName];
        
        if ([fileManager fileExistsAtPath:logFile])
        {
            logSize += [fileManager attributesOfItemAtPath:logFile error:nil].fileSize;
            
            if (logSize >= sizeLimit)
            {
                removeFiles = YES;
                break;
            }
        }
        else
        {
            break;
        }
    }
    
    if (removeFiles)
    {
        MXLogDebug(@"removeFilesAfterSizeLimit: Remove files from index %@ because logs are too large (%@ for a limit of %@)\n",
              @(index),
              [NSByteCountFormatter stringFromByteCount:logSize countStyle:NSByteCountFormatterCountStyleBinary],
              [NSByteCountFormatter stringFromByteCount:sizeLimit countStyle:NSByteCountFormatterCountStyleBinary]);
        [self removeExtraFilesFromCount:index];
    }
    else
    {
        MXLogDebug(@"removeFilesAfterSizeLimit: No need: %@ for a limit of %@\n",
              [NSByteCountFormatter stringFromByteCount:logSize countStyle:NSByteCountFormatterCountStyleBinary],
              [NSByteCountFormatter stringFromByteCount:sizeLimit countStyle:NSByteCountFormatterCountStyleBinary]);
    }
    
}
@end
