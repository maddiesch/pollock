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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.drawingView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.drawingView.layer.borderWidth = 1.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateStateLabel];
}

- (IBAction)clearAllDrawingsAction:(id)sender {
    [self.drawingView clearDrawings];
}

- (IBAction)saveDrawingsAction:(id)sender {
    [self.drawingView.renderer performOcclusionCullingWithError:NULL];

    NSLog(@"====================================");
    {
        NSString *path = @"/Users/skylar/Desktop/drawing-output.json";
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSData *data = [self.drawingView.renderer serializeWithCompression:NO error:NULL];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"\nUnCompressed:\n  %0.03fms\n  %@",((end - start) * 1000.0),[NSByteCountFormatter stringFromByteCount:data.length countStyle:NSByteCountFormatterCountStyleFile]);
#if TARGET_OS_SIMULATOR
        [data writeToFile:path atomically:YES];
#endif
    }
    {
        NSString *path = @"/Users/skylar/Desktop/drawing-output.pollock";
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSData *data = [self.drawingView.renderer serializeWithCompression:YES error:NULL];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"\nCompressed:\n  %0.03fms\n  %@",((end - start) * 1000.0), [NSByteCountFormatter stringFromByteCount:data.length countStyle:NSByteCountFormatterCountStyleFile]);
#if TARGET_OS_SIMULATOR
        [data writeToFile:path atomically:YES];
#endif
    }
    NSLog(@"====================================");

    {
        NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
        NSString *path = [dir stringByAppendingPathComponent:@"drawing.zlib"];
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        NSData *data = [self.drawingView.renderer serializeWithCompression:YES error:NULL];

        if (![data writeToFile:path atomically:YES]) {
            NSLog(@"Failed to save test file");
        } else {
            NSLog(@"SAVED: %@",path);
        }
    }
}

- (void)loadDrawingAction:(id)sender {
//    NSString *path = @"/Users/skylar/Desktop/test-out.zlib";
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"drawing.zlib"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        NSLog(@"No saved drawing");
        return;
    }
    NSError *error = nil;
    if (![self.drawingView.renderer loadSerializedData:data error:&error]) {
        NSLog(@"Load Error: %@",error);
    }
    [self.drawingView setNeedsDisplay];
}

- (IBAction)toggleSmoothingAction:(id)sender {
    [self.drawingView setIsSmoothingEnabled:!self.drawingView.isSmoothingEnabled];
    [self updateStateLabel];
}

- (void)toolSelectValueAction:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0: {
            self.drawingView.currentTool = [[POLPenTool alloc] init];
            break;
        }
        case 1: {
            self.drawingView.currentTool = [[POLHighlighterTool alloc] init];
            break;
        }
        case 2: {
            self.drawingView.currentTool = [[POLEraserTool alloc] init];
            break;
        case 3: {
            self.drawingView.currentTool = [[POLTextTool alloc] init];
            break;
        }
        }
    }
    [self updateStateLabel];
}

- (void)updateStateLabel {
    self.statusLabel.text = [NSString stringWithFormat:@"t:%@ <%f> s:%d",NSStringFromClass(self.drawingView.currentTool.class),self.drawingView.currentTool.lineWidth,self.drawingView.isSmoothingEnabled];
}

@end
