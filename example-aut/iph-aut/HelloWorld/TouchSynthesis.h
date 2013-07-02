//
//  TouchSynthesis.h
//  SelfTesting
//
//  Created by Matt Gallagher on 23/11/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>

#ifdef __IPHONE_6_0
@interface UITouch () {
    NSTimeInterval _timestamp;
    UITouchPhase _phase;
    UITouchPhase _savedPhase;
    NSUInteger _tapCount;
    
    UIWindow *_window;
    UIView *_view;
    UIView *_gestureView;
    UIView *_warpedIntoView;
    NSMutableArray *_gestureRecognizers;
    NSMutableArray *_forwardingRecord;
    
    CGPoint _locationInWindow;
    CGPoint _previousLocationInWindow;
    UInt8 _pathIndex;
    UInt8 _pathIdentity;
    float _pathMajorRadius;
    struct {
        unsigned int _firstTouchForView:1;
        unsigned int _isTap:1;
        unsigned int _isDelayed:1;
        unsigned int _sentTouchesEnded:1;
        unsigned int _abandonForwardingRecord:1;
    } _touchFlags;
}
@end
#endif

//
// UITouch (Synthesize)
//
// Category to allow creation and modification of UITouch objects.
//
@interface UITouch (Synthesize)

- (id)initInView:(UIView *)view;
- (void)setPhase:(UITouchPhase)phase;
- (void)setLocationInWindow:(CGPoint)location;

@end

//
// UIEvent (Synthesize)
//
// A category to allow creation of a touch event.
//
@interface UIEvent (Synthesize)

- (id)initWithTouch:(UITouch *)touch;

@end
