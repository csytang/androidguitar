//
//  ScriptRunner.m
//  SelfTesting
//
//  Created by Matt Gallagher on 9/10/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
/* 
 Edited by CMSC 435 04/25/2012
 Added screenshot ripping
 Hard coded in #windows so GUITAR knows how many windows to query for
 Hard coded in how to get to these windows (the buttons that cause switching)
	Also updated GUI structure to reflect that these windows cause switching
 There are duplicates when ripping Window 1 and then Window 2, so we had a loop
	that removed any INVOKE events that were duplicates
 */


#ifdef SCRIPT_DRIVEN_TEST_MODE_ENABLED

#import "ScriptRunner.h"
#import "UIView+FullDescription.h"
#import "XPathQuery.h"
#import "TouchSynthesis.h"
#import <stdio.h>
#import <stdlib.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSObject.h>

@interface Coordinates : NSObject {
	int x;
	int y;
}

- (Coordinates*)initWithX:(int)x andY:(int)y;
- (int) x;
- (int) y;

@end

@implementation Coordinates

- (Coordinates*)initWithX:(int)xIn andY:(int)yIn {
    if (self = [super init]) {
		x	= xIn;
		y	= yIn;
    }
    return self;
}

- (int) x {
	return x;
}

- (int) y {
	return y;
}

- (void)dealloc {
    [super dealloc];
}

@end

const float SCRIPT_RUNNER_INTER_COMMAND_DELAY = .5;

@implementation ScriptRunner

@synthesize delegate;
@synthesize callback;
@synthesize errorCallback;

//
// init
//
// Init method for the object.
// 
- (id)init
{
	self = [super init];
    
	if (self != nil)
	{
		windowNum = 0;
        
		buttonsTo = [[NSArray alloc] init]; // hard coded
		buttonsFrom = [[NSArray alloc] init]; // hard coded
		numWindows = 1;
        
		buttonsTo = [[NSArray arrayWithObjects: [[Coordinates alloc] initWithX:104 andY:309], nil] retain];
		buttonsFrom = [[NSArray arrayWithObjects: [[Coordinates alloc] initWithX:104 andY:262], nil] retain];
		
		prevGUI = [[NSMutableArray alloc] init]; // used to detect duplicates
		
        
        // Connect to the GUITAR Ripper Java server.		
        ripperSocket = [[[AsyncSocket alloc] initWithDelegate:self] retain];
        [ripperSocket connectToHost:@"localhost" onPort:8081 error:nil];
        
        /*
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)[website host], 8081, &readStream, &writeStream);
        
        inputStream_ = (NSInputStream *)readStream;
        outputStream_ = (NSOutputStream *)writeStream;
        
        [inputStream_ setDelegate:self];
        //[outputStream_ setDelegate:self];
        
        [inputStream_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        //[outputStream_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [inputStream_ open];
        [outputStream_ open];
         */
		
        
		guitarCommands = [[NSMutableArray alloc] init];
		[self retain];
		keep_running = YES;
		no_SDK = NO;
		
		//[self performSelector:@selector(runCommand) withObject:nil afterDelay:1.0];
	}
    
	return self;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	NSLog(@"Disconnecting. Error: %@", [err localizedDescription]);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	NSLog(@"Disconnected.");
	
	[ripperSocket setDelegate:nil];
	[ripperSocket release];
	ripperSocket = nil;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"iOS application connected to ripper %@:%u.", host, port);
    NSLog(@"Requesting instruction.");
    
    [self readFromRipperWithTag:2];
}

- (void)readFromRipperWithTag:(long)tag {
	[ripperSocket readDataToData:[AsyncSocket CRLFData] withTimeout:10 tag:tag];
}

- (void)writeToRipper:(NSString *)message withTag:(long)tag {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
	[ripperSocket writeData:data withTimeout:10 tag:tag];
}

/*
 * Asynchronous connection socket to GUITAR for ripper and replayer.
 * Redesigned by Nick Ink, iPhone GUITAR team, CMSC 435 Summer 2013 (06/17/13).
 *
 * The new GUITAR model (summer 2013) has client-server communication asynchronously
 * between the iOS app and the ripper and replayer. This corrects compatibility issues
 * with newer versions of iOS and allows better diagnostics for issues in the system.
 */
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSString *string = [[NSString alloc] initWithBytes:[data bytes] length:[data length]
                                              encoding:NSUTF8StringEncoding];
	NSLog(@"Received Data (Tag: %li): %@", tag, string);
    
    if ([string isEqualToString:@"invoke main method\r\n"]) {
        NSLog(@"Ripper requested invoke main method.");
        
        // We aren't in the SDK at this point.
        no_SDK = YES;
        
        NSLog(@"In main method call.");
        [self writeToRipper:@"Hello\r\n" withTag:3];
        NSLog(@"Finishing main method call.");
        
        [self readFromRipperWithTag:4];
    }
    
    else if ([string isEqualToString:@"get num windows\r\n"]) {
        NSLog(@"Ripper requested num windows.");
        
        no_SDK = YES;
        
        NSLog(@"Sent num windows. (%@)", [NSString stringWithFormat:@"%d", numWindows]);
        [self writeToRipper:[NSString stringWithFormat:@"%d\r\n", numWindows] withTag:5];
        
        [self readFromRipperWithTag:6];
    }
    
    else if ([string isEqualToString:@"get root window list\r\n"]) {
        NSLog(@"Ripper requested root window list.");
        
        windowNum++;
        NSString* keyWindowDescription = [[[UIApplication sharedApplication] keyWindow] fullDescription];
        
        [prevGUI addObject: keyWindowDescription];
        
        // add "Invokelist" property, saying that the button switches window
        for ( int i = 0; i < [buttonsTo count]; i++ ) {
            Coordinates *to = [buttonsTo objectAtIndex:i];
            NSString *search = [NSString stringWithFormat:
                                @"<Property><Name>x</Name><Value>%d</Value></Property><Property><Name>y</Name><Value>%d</Value></Property>",
                                to.x, to.y];
            NSRange range = [keyWindowDescription rangeOfString: search];
            if (range.length > 0) {
                NSString *append = [NSString stringWithFormat:@"<Property><Name>Invokelist</Name><Value>Window %d</Value></Property></Attributes>",
                                    i+2];
                NSRange range2search = NSMakeRange(range.location, [keyWindowDescription length] - range.location);
                NSRange endSearch = [keyWindowDescription rangeOfString:@"</Attributes>"
                                                                options:NSCaseInsensitiveSearch
                                                                  range:range2search];
                keyWindowDescription = [keyWindowDescription stringByReplacingCharactersInRange: endSearch
                                                                                     withString: append];
            }
        }
        
        NSString *keyWindowDescriptionServerFriendly = [NSString stringWithFormat:@"%@\r\n", keyWindowDescription];
        
        NSLog(@"Sending key window description: %@", keyWindowDescriptionServerFriendly);
        [self writeToRipper:keyWindowDescriptionServerFriendly withTag:7];
        
        [self readFromRipperWithTag:8];
        
        NSLog(@"finished sending root window.");
        
        NSLog(@"Taking screenshot.");
        [self takeScreenshot];
    }
    
    else if ([string isEqualToString:@"get new window\r\n"]) {
        // Added by CMSC435 04/25/2012
        // Rips additional windows
        
        Coordinates *to = [buttonsTo objectAtIndex:windowNum-1];
        Coordinates *from = [buttonsFrom objectAtIndex:windowNum-1];
        
        windowNum++;
        
        [self touchWindow:@"UIRoundedRectButton" x: [NSNumber numberWithInt:to.x] y:[NSNumber numberWithInt:to.y] ];
        NSLog( @"going to new view, touching button at x: %d, y: %d.", to.x, to.y );
        
        NSString* keyWindowDescription = [[[UIApplication sharedApplication] keyWindow] fullDescription];
        
        NSRange rangeMe = [keyWindowDescription rangeOfString: @"</Window>"];
        int startMe = rangeMe.location + rangeMe.length;
        
        // finds how many INVOKE events in previous GUIs
        int n_invoke = 0;
        for (id str in prevGUI) {
            NSRange rangeYou = [str rangeOfString: @"INVOKE"];
            while (rangeYou.length > 0) {
                NSRange range2search = NSMakeRange(rangeYou.location + rangeYou.length,
                                                   [str length] - rangeYou.location - rangeYou.length);
                n_invoke++;
                rangeYou = [str rangeOfString: @"INVOKE"
                                      options: nil
                                        range: range2search];
            }
        }
        // removes these INVOKE events, because they are duplicates
        for (int i = 0; i < n_invoke; i++) {
            NSRange rangeMe = [keyWindowDescription rangeOfString: @"INVOKE"];
            rangeMe.location -= [@"<Property><Name>" length];
            NSRange prop = [keyWindowDescription rangeOfString: @"</Property>"
                                                       options: nil
                                                         range: NSMakeRange(rangeMe.location, [keyWindowDescription length] - rangeMe.location)];
            rangeMe.length = prop.location + prop.length - rangeMe.location;
            keyWindowDescription = [keyWindowDescription stringByReplacingCharactersInRange:rangeMe
                                                                                 withString:@""];
            
        }
        
        [prevGUI addObject: keyWindowDescription];
        
        // add button goes back to first window
        NSString *search = [NSString stringWithFormat:
                            @"<Property><Name>x</Name><Value>%d</Value></Property><Property><Name>y</Name><Value>%d</Value></Property>",
                            from.x, from.y];
        NSRange range = [keyWindowDescription rangeOfString: search];
        if (range.length > 0) {
            NSString *append = [NSString stringWithFormat:@"<Property><Name>Invokelist</Name><Value>Window %d</Value></Property></Attributes>",
                                1];
            NSRange range2search = NSMakeRange(range.location, [keyWindowDescription length] - range.location);
            NSRange endSearch = [keyWindowDescription rangeOfString:@"</Attributes>"
                                                            options:nil
                                                              range:range2search];
            keyWindowDescription = [keyWindowDescription stringByReplacingCharactersInRange: endSearch
                                                                                 withString: append];
        }
        
        NSString *keyWindowDescriptionServerFriendly = [NSString stringWithFormat:@"%@\r\n", keyWindowDescription];
        
        NSLog(@"%@", keyWindowDescription);
        [self writeToRipper:keyWindowDescriptionServerFriendly withTag:20];
        [self readFromRipperWithTag:21];
        
        [self takeScreenshot];
        
        [self touchWindow:@"UIRoundedRectButton" x:[NSNumber numberWithInt:from.x] y:[NSNumber numberWithInt:from.y]];
        NSLog( @"returning from new view, touching button at x: %d, y: %d.", from.x, from.y );
        NSLog( @"finished sending new window." );
    }
    
    else if ([string hasPrefix:@"INVOKE"]) {
        // [self sendText:@"Received INVOKE request!"];
        NSArray *chunks = [string componentsSeparatedByString: @" "];
        
        // Handle command (just TOUCH for the time being).
        if ([[chunks objectAtIndex:1] isEqualToString:@"TOUCH"]) {
            NSLog(@"Received TOUCH request.");
            
            NSString* class = [chunks objectAtIndex:2];
            NSNumber *x = [NSNumber numberWithInt:[[chunks objectAtIndex:3] intValue]];
            NSNumber *y = [NSNumber numberWithInt:[[chunks objectAtIndex:4] intValue]];
            
            // Find the desire subview.
            UIView* viewToTouch = [[[UIApplication sharedApplication] keyWindow]
                                   findViewWithClass:class andX:x andY:y];
            
            if (viewToTouch) {
                NSLog(@"Found a good view to touch!");
                NSDictionary* newGuitarCommand = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  class, @"class",
                                                  x, @"x",
                                                  y, @"y",
                                                  @"INVOKE_TOUCH", @"action",
                                                  nil];
                
                [guitarCommands addObject:newGuitarCommand];
                
                [self performTouchInView:viewToTouch];
            } else {
                NSLog(@"Found no good view to touch :(");
            }
            
            NSLog(@"Sending response back");
            [self writeToRipper:[NSString stringWithFormat:@"Touch happened for %@!\r\n", class] withTag:10];
            [self readFromRipperWithTag:11];
        }
        // Handle command (just TOUCH for the time being).
        else if ([[chunks objectAtIndex:1] isEqualToString:@"PICKER_WHEEL"]) {
            NSLog(@"Received PICKER_WHEEL request.");
            
            NSString* class = [chunks objectAtIndex:2];
            NSNumber *x = [NSNumber numberWithInt:[[chunks objectAtIndex:3] intValue]];
            NSNumber *y = [NSNumber numberWithInt:[[chunks objectAtIndex:4] intValue]];
            
            // Find the desire subview.
            UIView* viewToTouch = [[[UIApplication sharedApplication] keyWindow]
                                   findViewWithClass:class andX:x andY:y];
            
            if (viewToTouch) {
                NSLog(@"Found a good view to touch!");
                NSDictionary* newGuitarCommand = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  class, @"class",
                                                  x, @"x",
                                                  y, @"y",
                                                  @"INVOKE_PICKER_WHEEL", @"action",
                                                  nil];
                
                [guitarCommands addObject:newGuitarCommand];
                
                [self performPickerWheel:viewToTouch];
            } else {
                NSLog(@"Found no good view to touch :(");
            }
            
            NSLog(@"Sending response back");
            [self writeToRipper:[NSString stringWithFormat:@"PICKER_WHEEL happened for %@!", class] withTag:12];
            [self readFromRipperWithTag:13];
        }
    }
    
    else {
        NSLog(@"Received unknown command from ripper: %@", string);
    }
    
	[string release];
}

/*
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"Wrote to ripper with tag %li.", tag);
}
 */

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[buttonsTo release];
	[buttonsFrom release];
	[guitarCommands dealloc];
    [ripperSocket dealloc];
	[super dealloc];
}

- (void)takeScreenshot {
	// Added by CMSC435 04/25/2012
	// Takes a screenshot and saves it to the Demo folder
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	UIViewController *controller = window.rootViewController;
	UIGraphicsBeginImageContext(controller.view.bounds.size);
	[controller.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImageWriteToSavedPhotosAlbum(viewImage, nil, nil, nil);
	NSData* imageData = UIImageJPEGRepresentation (viewImage, 1.0);
	[imageData writeToFile:[NSString stringWithFormat:@"Demo/screenshots/img%03d.jpg", windowNum] atomically:NO];
}

- (BOOL)touchWindow:(NSString *)class x:(NSNumber *)x y:(NSNumber *)y {						
	// Find the desire subview.
	UIView* viewToTouch = [[[UIApplication sharedApplication] keyWindow]
						   findViewWithClass:class andX:x andY:y];
	
	if (viewToTouch) {
		NSLog(@"Found a good view to touch!");								
		[self performTouchInView:viewToTouch];
		return TRUE;
	} else {
		NSLog(@"Found no good view to touch :(");
		return FALSE;
	}
}

//
// performTouchInView:
//
// Synthesize a touch begin/end in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performTouchInView:(UIView *)view
{
	UITouch *touch = [[UITouch alloc] initInView:view];
	UIEvent *eventDown = [[UIEvent alloc] initWithTouch:touch];
	
	[touch.view touchesBegan:[eventDown allTouches] withEvent:eventDown];
	[touch setPhase:UITouchPhaseEnded];
	UIEvent *eventUp = [[UIEvent alloc] initWithTouch:touch];
	
	[touch.view touchesEnded:[eventUp allTouches] withEvent:eventUp];
	
	[eventDown release];
	[eventUp release];
	[touch release];
}

- (void)performPickerWheel:(UIView *)view
{
	NSLog(@"Inside perform pickerwheel.");
	UIPickerView* picker = (UIPickerView *)view;
	
	// Select a random component, and a random row index.
	int componentIndex = arc4random() % [picker numberOfComponents];
	int rowIndex = arc4random() % [picker numberOfRowsInComponent:componentIndex];
	[picker selectRow:rowIndex inComponent:componentIndex animated:YES];
}

//
// viewsForXPath:
//
// Generates an XML document from the current view tree and runs the specified
// XPath query on the document. If the resulting nodes contain "address" values
// then these values are interrogated to determine if they are UIViews. All
// UIViews found in this way are returned in the array.
//
- (NSArray *)viewsForXPath:(NSString *)xpath
{
	NSDictionary *keyWindowDescription =
		[[[UIApplication sharedApplication] keyWindow] fullDescription];
	NSData *resultData =
		[NSPropertyListSerialization
			dataFromPropertyList:keyWindowDescription
			format:NSPropertyListXMLFormat_v1_0
			errorDescription:nil];

	NSArray *queryResults = PerformXMLXPathQuery(resultData, xpath);
	NSMutableArray *views =
		[NSMutableArray arrayWithCapacity:[queryResults count]];
	for (NSDictionary *result in queryResults)
	{
		int i;
		int count = [[result objectForKey:@"nodeChildArray"] count];
		for (i = 0; i < count; i++)
		{
			NSDictionary *childNode = [[result objectForKey:@"nodeChildArray"] objectAtIndex:i];
			if ([[childNode objectForKey:@"nodeName"] isEqualToString:@"key"] &&
				[[childNode objectForKey:@"nodeContent"] isEqualToString:@"address"])
			{	
				if (i < count - 1)
				{
					NSDictionary *nextNode = [[result objectForKey:@"nodeChildArray"] objectAtIndex:i + 1];
					UIView *view =
						(UIView *)[[nextNode objectForKey:@"nodeContent"] integerValue];
					NSAssert([view isKindOfClass:[UIView class]],
						@"XPath selected memory address did not contain a UIView");
					[views addObject:view];
					break;
				}
			}
		}
	}
	
	return views;
}

//
// runCommand
//
// Runs the first command in the scriptCommands array and then removes it from
// the array.
//
// Two commands are supported:
//	- outputView (writes the XML for a view hierarchy to a file)
//	- simulateTouch (selects a UIView by XPath and simulates a touch within it)
//
- (void)runCommand
{
	// If we are in the SDK, load the guitar commands from the file,
	// otherwise exit gracefully.
	if (no_SDK) {
		[NSThread sleepForTimeInterval:2];
		NSLog(@"Writing out guitar commands: %@", guitarCommands);
		[guitarCommands writeToFile:@"/tmp/guitarCommands.plist" atomically:YES];
		NSLog(@"Shutting down");
		[self release];
		exit(0);
	} else {
		if ([guitarCommands count] == 0) {
			guitarCommands = [[NSMutableArray alloc] initWithContentsOfFile:@"/tmp/guitarCommands.plist"];
		}
		NSLog(@"Performing guitar commands: %@", guitarCommands);			
		if ([guitarCommands count] == 0) {
			NSLog(@"Waiting for an action...");
			[NSThread sleepForTimeInterval:.3];
		} else {
			NSDictionary *guitarCommand = [guitarCommands objectAtIndex:0];
			NSLog(@"Performing guitar command: %@", guitarCommand);

			// Find the desire subview.
			UIView* viewToTouch = [[[UIApplication sharedApplication] keyWindow]
								   findViewWithClass:[guitarCommand objectForKey:@"class"]
								   andX:[guitarCommand objectForKey:@"x"]
								   andY:[guitarCommand objectForKey:@"y"]];
			
			NSLog(@"action: %@", [guitarCommand objectForKey:@"action"]);
			if ([@"INVOKE_PICKER_WHEEL" isEqualToString:[guitarCommand objectForKey:@"action"]]) {
				NSLog(@"Performing picker wheel replay.");
				[self performPickerWheel:viewToTouch];
			} else {
				NSLog(@"Performing touch replay.");
				[self performTouchInView:viewToTouch];
			}
		}
	}

	//
	// Remove each command after execution
	//
	[guitarCommands removeObjectAtIndex:0];

	//
	// Exit the program when complete
	//
	if ([guitarCommands count] == 0) {
		[self
		 performSelector:@selector(dieQuietly)
		 withObject:nil
		 afterDelay:SCRIPT_RUNNER_INTER_COMMAND_DELAY];
	}
	else {
		//
		// If further commands remain, queue the next one
		//
		[self
		 performSelector:@selector(runCommand)
		 withObject:nil
		 afterDelay:SCRIPT_RUNNER_INTER_COMMAND_DELAY];
	}
}

- (void) dieQuietly {
	[self release];
	exit(0);
}

@end

#endif

