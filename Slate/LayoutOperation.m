//
//  LayoutOperation.m
//  Slate
//
//  Created by Jigish Patel on 6/14/11.
//  Copyright 2011 Jigish Patel. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses

#import "Layout.h"
#import "LayoutOperation.h"
#import "SlateConfig.h"


@implementation LayoutOperation

@synthesize name;

- (id)init {
  self = [super init];
  return self;
}

- (id)initWithName:(NSString *)theName {
  self = [self init];
  if (self) {
    [self setName:theName];
  }
  return self;
}

- (BOOL)doOperation {
  BOOL success = YES;
  NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
  for (NSInteger i = 0; i < [apps count]; i++) {
    NSDictionary *app = [apps objectAtIndex:i];
    NSString *appName = [app objectForKey:@"NSApplicationName"];
    NSNumber *appPID = [app objectForKey:@"NSApplicationProcessIdentifier"];
    NSLog(@"I see application '%@' with pid '%@'", appName, appPID);
    Layout *layout = [[[SlateConfig getInstance] layouts] objectForKey:[self name]];
    if (layout == nil) {
      @throw([NSException exceptionWithName:@"Unrecognized Layout" reason:[self name] userInfo:nil]);
    }
    NSArray *operations = [[layout appStates] objectForKey:appName];
    if (operations == nil) {
      continue;
    }
    AXUIElementRef appRef = AXUIElementCreateApplication([appPID intValue]);
    CFArrayRef windows = [AccessibilityWrapper windowsInApp:appRef];
    NSInteger failedWindows = 0;
    for (NSInteger i = 0; i < CFArrayGetCount(windows) && i-failedWindows < [operations count]; i++) {
      AccessibilityWrapper *aw = [[AccessibilityWrapper alloc] initWithApp:appRef window:CFArrayGetValueAtIndex(windows, i)];
      success = [[operations objectAtIndex:(i-failedWindows)] doOperation:aw] && success;
      if (!success)
        failedWindows++;
      [aw release];
    }
  }
  return success;
}

- (BOOL)testOperation:(Operation *)op {
  BOOL success = [op testOperation];
  return success;
}

- (BOOL)testOperation {
  BOOL success = YES;
  Layout *layout = [[[SlateConfig getInstance] layouts] objectForKey:[self name]];
  if (layout == nil) {
    @throw([NSException exceptionWithName:@"Unrecognized Layout" reason:[self name] userInfo:nil]);
  }
  NSArray *apps = [[layout appStates] allKeys];
  for (NSInteger i = 0; i < [apps count]; i++) {
    NSArray *ops = [[layout appStates] objectForKey:[apps objectAtIndex:i]];
    for (NSInteger op = 0; op < [ops count]; op++) {
      [self testOperation:[ops objectAtIndex:op]];
    }
  }
  return success;
}

@end