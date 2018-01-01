//
//  RWTViewController.m
//  DynamicToss
//
//  Created by Main Account on 7/13/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import "RWTViewController.h"

static const CGFloat ThrowingThreshold = 1000;
static const CGFloat ThrowingvelocityPadding = 35;

@interface RWTViewController ()
@property (nonatomic, weak) IBOutlet UIView *image;
@property (nonatomic, weak) IBOutlet UIView *redSquare;
@property (nonatomic, weak) IBOutlet UIView *blueSquare;

@property (nonatomic, assign) CGRect originalBounds;
@property (nonatomic, assign) CGPoint originalCenter;

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic) UIPushBehavior *pushBehavior;
@property (nonatomic) UIDynamicItemBehavior *itemBehavior;
@end

@implementation RWTViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
  self.originalBounds = self.image.bounds;
  self.originalCenter = self.image.center;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (IBAction) handleAttachmentGesture:(UIPanGestureRecognizer*)gesture
{
    CGPoint location = [gesture locationInView:self.view];
    CGPoint boxLocation = [gesture locationInView:self.image];
    
    switch (gesture.state) {
    case UIGestureRecognizerStateBegan:{
        NSLog(@"you touch started position %@",NSStringFromCGPoint(location));
        NSLog(@"location in image started is %@",NSStringFromCGPoint(boxLocation));

        [self.animator removeAllBehaviors];
                    
        // Create an attachment binding the anchor point (the finger's current location)
        // to a certain position on the view (the offset)
        UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.image.bounds),
                                             boxLocation.y - CGRectGetMidY(self.image.bounds));
        self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.image
                                                            offsetFromCenter:centerOffset
                                                            attachedToAnchor:location];

        // Update the red and blue boxes, so we can see the 
        // touch start in blue and the anchor point in red
        self.redSquare.center = self.attachmentBehavior.anchorPoint;
        self.blueSquare.center = location;

        // Tell the animator to use this attachment behavior
        [self.animator addBehavior:self.attachmentBehavior];

        break;
    }
    case UIGestureRecognizerStateEnded: {
        [self.animator removeBehavior:self.attachmentBehavior];

        //1
        CGPoint velocity = [gesture velocityInView:self.view];
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));

        if (magnitude > ThrowingThreshold) {
            //2
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc]
                                            initWithItems:@[self.image]
                                            mode:UIPushBehaviorModeInstantaneous];
            pushBehavior.pushDirection = CGVectorMake((velocity.x / 10) , (velocity.y / 10));
            pushBehavior.magnitude = magnitude / ThrowingvelocityPadding;

            self.pushBehavior = pushBehavior;
            [self.animator addBehavior:self.pushBehavior];

            //3
            NSInteger angle = arc4random_uniform(20) - 10;

            self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.image]];
            self.itemBehavior.friction = 0.2;
            self.itemBehavior.allowsRotation = YES;
            [self.itemBehavior addAngularVelocity:angle forItem:self.image];
            [self.animator addBehavior:self.itemBehavior];

            //4
            [self performSelector:@selector(resetDemo) withObject:nil afterDelay:0.4];
        }

        else {
            [self resetDemo];
        }

        break;
    }
    default:
        [self.attachmentBehavior setAnchorPoint:[gesture locationInView:self.view]];
        self.redSquare.center = self.attachmentBehavior.anchorPoint;
        break;
    }
}

- (void)resetDemo
{
    // This  kill an existing push too
    [self.animator removeAllBehaviors];
    
    [UIView animateWithDuration:0.45 animations:^{
        // UIDynamics doesn't use .frame, it uses .center & .bounds like CALayers do.
        self.image.bounds = self.originalBounds;
        self.image.center = self.originalCenter;
        self.image.transform = CGAffineTransformIdentity;
    }];
}

@end
