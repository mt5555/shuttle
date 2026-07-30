//
//  LaunchAtLoginController.m
//
//  Copyright 2011 Tomáš Znamenáček
//  Copyright 2010 Ben Clark-Robinson
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the ‘Software’),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  This file originally wrapped LSSharedFileList, deprecated in macOS 10.11 and
//  marked "no longer supported" in the system headers. It is unreliable rather
//  than uniformly broken: rebuilt from source it still registers on macOS 26,
//  yet the shipped 1.2.9 release fails to register on a current system even with
//  launch_at_login set. SMAppService is the sanctioned replacement but requires a
//  Team ID and rejects an ad-hoc signature, so it is unavailable to a build
//  anyone can produce for free. A plain launchd LaunchAgent carries no signing
//  requirement and behaves the same way whoever built the binary.

#import "LaunchAtLoginController.h"
#import <unistd.h>

static NSString *const kLabel = @"shuttle.Shuttle.LaunchAtLogin";
static NSString *const StartAtLoginKey = @"launchAtLogin";

@implementation LaunchAtLoginController

#pragma mark Agent Location

- (NSString*) plistPath
{
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents"];
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", kLabel]];
}

#pragma mark Launch Agent Control

- (void) install
{
    NSString *path = [self plistPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES attributes:nil error:NULL];

    NSDictionary *job = @{
        @"Label": kLabel,
        // open(1) rather than the inner executable: it goes through Launch
        // Services, which is the better behaved path for a bundled LSUIElement app.
        @"ProgramArguments": @[@"/usr/bin/open", @"-a", [[NSBundle mainBundle] bundlePath]],
        @"RunAtLoad": @YES,
    };

    // Deliberately not bootstrapped here. launchd reads ~/Library/LaunchAgents at
    // login, which is exactly the semantics we want; bootstrapping now would fire
    // RunAtLoad immediately and start a second copy of the app.
    [job writeToFile:path atomically:YES];
}

- (void) uninstall
{
    NSString *path = [self plistPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return;

    // Best effort, in case a previous login already bootstrapped the agent.
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = @[@"bootout", [NSString stringWithFormat:@"gui/%u/%@", getuid(), kLabel]];
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError  = [NSFileHandle fileHandleWithNullDevice];
    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        // Not loaded, nothing to unload.
    }

    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

#pragma mark Basic Interface

- (BOOL) launchAtLogin
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self plistPath]];
}

- (void) setLaunchAtLogin: (BOOL) enabled
{
    [self willChangeValueForKey:StartAtLoginKey];
    if (enabled)
        [self install];
    else
        [self uninstall];
    [self didChangeValueForKey:StartAtLoginKey];
}

@end
