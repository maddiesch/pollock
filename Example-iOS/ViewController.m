//
//  ViewController.m
//  Example-iOS
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)clearAllDrawingsAction:(id)sender {
    [self.drawingView clearDrawings];
}

- (IBAction)saveDrawingsAction:(id)sender {
    NSLog(@"====================================");
    {
        NSString *path = @"/Users/skylar/Desktop/drawing-output.json";
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSData *data = [self.drawingView serializeUsingCompression:NO error:NULL];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"Serialize UnCompressed: %0.03fms",((end - start) * 1000.0));
#if TARGET_OS_SIMULATOR
        [data writeToFile:path atomically:YES];
#else
        NSLog(@"UnCompressed: %@",[NSByteCountFormatter stringFromByteCount:data.length countStyle:NSByteCountFormatterCountStyleFile]);
#endif
    }
    {
        NSString *path = @"/Users/skylar/Desktop/drawing-output.pollock";
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSData *data = [self.drawingView serializeUsingCompression:YES error:NULL];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"Serialize Compressed: %0.03fms",((end - start) * 1000.0));
        [data writeToFile:path atomically:YES];
#if TARGET_OS_SIMULATOR
        [data writeToFile:path atomically:YES];
#else
        NSLog(@"Compressed: %@",[NSByteCountFormatter stringFromByteCount:data.length countStyle:NSByteCountFormatterCountStyleFile]);
#endif
    }
    NSLog(@"====================================");
}

@end
