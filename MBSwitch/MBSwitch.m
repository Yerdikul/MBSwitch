//
//  MBSwitch.m
//  MBSwitchDemo
//
//  Created by Mathieu Bolard on 22/06/13.
//  Copyright (c) 2013 Mathieu Bolard. All rights reserved.
//

#import "MBSwitch.h"
#import <QuartzCore/QuartzCore.h>


@interface MBSwitch () <UIGestureRecognizerDelegate> {
    CAShapeLayer *_thumbLayer;
    CAShapeLayer *_offLayer;
    CAShapeLayer *_onLayer;
    CAShapeLayer *_backLayer;
    BOOL _dragging;
    BOOL _on;
}
@property (nonatomic, assign) BOOL pressed;
- (void) setBackgroundOn:(BOOL)on animated:(BOOL)animated;
- (void) showFillLayer:(BOOL)show animated:(BOOL)animated;
- (CGRect) thumbFrameForState:(BOOL)isOn;
@end

@implementation MBSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

- (void) awakeFromNib {
    [self configure];
}

- (void) configure {
    //Check width > height
    if (self.frame.size.height > self.frame.size.width*0.65) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ceilf(0.6*self.frame.size.width));
    }
    
    [self setBackgroundColor:[UIColor clearColor]];
    self.onTintColor = [UIColor colorWithRed:0.27f green:0.85f blue:0.37f alpha:1.00f];
    self.tintColor = [UIColor colorWithRed:0.90f green:0.90f blue:0.90f alpha:1.00f];
    self.offTintColor = [UIColor whiteColor];
    
    _on = NO;
    _pressed = NO;
    _dragging = NO;
    
    _backLayer = [[CAShapeLayer layer] retain];
    _backLayer.backgroundColor = [_tintColor CGColor];
    _backLayer.frame = self.bounds;
    _backLayer.cornerRadius = self.bounds.size.height/2.0;

    [self.layer addSublayer:_backLayer];

    _onLayer = [[CAShapeLayer layer] retain];
    _onLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _onLayer.frame = CGRectInset(self.bounds, 1.5, 1.5);
    _onLayer.cornerRadius = _onLayer.bounds.size.height/2.0;
    CGPathRef path1 = [UIBezierPath bezierPathWithRoundedRect:_onLayer.bounds cornerRadius:floorf(_onLayer.bounds.size.height/2.0)].CGPath;
    _onLayer.path = path1;
    [_onLayer setValue:[NSNumber numberWithBool:NO] forKey:@"isOn"];
    _onLayer.fillColor = [_tintColor CGColor];
    
    [self.layer addSublayer:_onLayer];
    
    _offLayer = [[CAShapeLayer layer] retain];
    _offLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _offLayer.frame = CGRectInset(self.bounds, 1.5, 1.5);

    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:_offLayer.bounds cornerRadius:floorf(_offLayer.bounds.size.height/2.0)].CGPath;
    _offLayer.path = path;
    [_offLayer setValue:[NSNumber numberWithBool:YES] forKey:@"isVisible"];
    _offLayer.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:_offLayer];
    
    
    _thumbLayer = [[CAShapeLayer layer] retain];
    _thumbLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _thumbLayer.frame = CGRectMake(1.0, 1.0, self.bounds.size.height-2.0, self.bounds.size.height-2.0);
    _thumbLayer.cornerRadius = self.bounds.size.height/2.0;
    CGPathRef knobPath = [UIBezierPath bezierPathWithRoundedRect:_thumbLayer.bounds cornerRadius:floorf(_thumbLayer.bounds.size.height/2.0)].CGPath;
    _thumbLayer.path = knobPath;
    _thumbLayer.fillColor = [UIColor whiteColor].CGColor;
    _thumbLayer.shadowColor = [UIColor blackColor].CGColor;
    _thumbLayer.shadowOffset = CGSizeMake(0.0, 3.0);
    _thumbLayer.shadowRadius = 3.0;
    _thumbLayer.shadowOpacity = 0.3;
    [self.layer addSublayer:_thumbLayer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(tapped:)];
    [tapGestureRecognizer setDelegate:self];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(toggleDragged:)];
    //[panGestureRecognizer requireGestureRecognizerToFail:tapGestureRecognizer];
    [panGestureRecognizer setDelegate:self];
    [self addGestureRecognizer:panGestureRecognizer];
    
    [tapGestureRecognizer release];
    [panGestureRecognizer release];
}

#pragma mark -
#pragma mark Animations

- (BOOL) isOn {
    return _on;
}

- (void) setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    
    if (_on != on) {
        _on = on;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setDisableActions:NO];
        _thumbLayer.frame = [self thumbFrameForState:_on];
        [CATransaction commit];
    }else {
        [CATransaction setDisableActions:YES];
        _thumbLayer.frame = [self thumbFrameForState:_on];
    }
    [self setBackgroundOn:_on animated:animated];
    [self showFillLayer:!_on animated:animated];
    [self updateBackLayerColorWithanimated:animated];
}

- (void) setBackgroundOn:(BOOL)on animated:(BOOL)animated {
    BOOL isOn = [[_onLayer valueForKey:@"isOn"] boolValue];
    if (on != isOn) {
        [_onLayer setValue:[NSNumber numberWithBool:on] forKey:@"isOn"];
        if (animated) {
            CABasicAnimation *animateColor = [CABasicAnimation animationWithKeyPath:@"fillColor"];
            animateColor.duration = 0.22;
            animateColor.fromValue = on ? (id)_tintColor.CGColor : (id)_onTintColor.CGColor;
            animateColor.toValue = on ? (id)_onTintColor.CGColor : (id)_tintColor.CGColor;
            animateColor.removedOnCompletion = NO;
            animateColor.fillMode = kCAFillModeForwards;
            [_onLayer addAnimation:animateColor forKey:@"animateColor"];
            [CATransaction commit];
        }else {
            [_onLayer removeAllAnimations];
            _onLayer.fillColor = on ? _onTintColor.CGColor : _tintColor.CGColor;
        }
    }
}

- (void) showFillLayer:(BOOL)show animated:(BOOL)animated {
    BOOL isVisible = [[_offLayer valueForKey:@"isVisible"] boolValue];
    if (isVisible != show) {
        [_offLayer setValue:[NSNumber numberWithBool:show] forKey:@"isVisible"];
        CGFloat scale = show ? 1.0 : 0.0;
        if (animated) {
            CGFloat from = show ? 0.0 : 1.0;
            CABasicAnimation *animateScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            animateScale.duration = 0.22;
            animateScale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(from, from, 1.0)];
            animateScale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale, scale, 1.0)];
            animateScale.removedOnCompletion = NO;
            animateScale.fillMode = kCAFillModeForwards;
            animateScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [_offLayer addAnimation:animateScale forKey:@"animateScale"];
        }else {
            [_offLayer removeAllAnimations];
            _offLayer.transform = CATransform3DMakeScale(scale,scale,1.0);
        }
    }
}

- (void) updateBackLayerColorWithanimated:(BOOL)animated {
        if (animated) {
            CABasicAnimation *animateColor = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
            animateColor.duration = 0.22;
            animateColor.fromValue = _on ? (id)_onTintColor.CGColor : (id)self.offTintColor.CGColor;
            animateColor.toValue = _on ? (id)self.offTintColor.CGColor : (id)_onTintColor.CGColor;
            animateColor.removedOnCompletion = NO;
            animateColor.fillMode = kCAFillModeForwards;
            [_backLayer addAnimation:animateColor forKey:@"animateColor"];
            [CATransaction commit];
        }else {
            [_backLayer removeAllAnimations];
            _backLayer.backgroundColor = _on ? self.offTintColor.CGColor : _onTintColor.CGColor;
        }
}

- (void) setPressed:(BOOL)pressed {
    if (_pressed != pressed) {
        _pressed = pressed;
        
        if (!_on) {
            [self showFillLayer:!_pressed animated:YES];
        }
    }
}

#pragma mark -
#pragma mark Appearance

- (void) setTintColor:(UIColor *)tintColor {
    _tintColor = [tintColor retain];
    if (![[_onLayer valueForKey:@"isOn"] boolValue]) {
        _onLayer.fillColor = [_tintColor CGColor];
    }
}

- (void) setOnTintColor:(UIColor *)onTintColor {
    _onTintColor = [onTintColor retain];
    if ([[_onLayer valueForKey:@"isOn"] boolValue]) {
        _onLayer.fillColor = [_onTintColor CGColor];
    }
}

- (void) setOffTintColor:(UIColor *)offTintColor {
    _offLayer.fillColor = [offTintColor CGColor];
}

- (UIColor *) offTintColor {
    return [UIColor colorWithCGColor:_offLayer.fillColor];
}

- (void) setThumbTintColor:(UIColor *)thumbTintColor {
    _thumbLayer.fillColor = [thumbTintColor CGColor];
}

- (UIColor *) thumbTintColor {
    return [UIColor colorWithCGColor:_thumbLayer.fillColor];
}

#pragma mark -
#pragma mark Interaction

- (void)tapped:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
        [self setOn:!self.on animated:YES];
}

- (void)toggleDragged:(UIPanGestureRecognizer *)gesture
{
    CGFloat minToggleX = 1.0;
    CGFloat maxToggleX = self.bounds.size.width-self.bounds.size.height+1.0;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        self.pressed = YES;
        _dragging = YES;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [gesture translationInView:self];
        
        [CATransaction setDisableActions:YES];
        
        self.pressed = YES;
        
        CGFloat newX = _thumbLayer.frame.origin.x + translation.x;
        if (newX < minToggleX) newX = minToggleX;
        if (newX > maxToggleX) newX = maxToggleX;
        _thumbLayer.frame = CGRectMake(newX,
                                       _thumbLayer.frame.origin.y,
                                       _thumbLayer.frame.size.width,
                                       _thumbLayer.frame.size.height);
        
        if (CGRectGetMidX(_thumbLayer.frame) > CGRectGetMidX(self.bounds)
            && ![[_onLayer valueForKey:@"isOn"] boolValue]) {
            [self setBackgroundOn:YES animated:YES];
        }else if (CGRectGetMidX(_thumbLayer.frame) < CGRectGetMidX(self.bounds)
                  && [[_onLayer valueForKey:@"isOn"] boolValue]){
            [self setBackgroundOn:NO animated:YES];
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        CGFloat toggleCenter = CGRectGetMidX(_thumbLayer.frame);
        [self setOn:(toggleCenter > CGRectGetMidX(self.bounds)) animated:YES];
        _dragging = NO;
        self.pressed = NO;
    }
    
    CGPoint locationOfTouch = [gesture locationInView:self];
    if (CGRectContainsPoint(self.bounds, locationOfTouch))
        [self sendActionsForControlEvents:UIControlEventTouchDragInside];
    else
        [self sendActionsForControlEvents:UIControlEventTouchDragOutside];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    self.pressed = YES;
    
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (!_dragging) {
        self.pressed = NO;
    }
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (!_dragging) {
        self.pressed = NO;
    }
    [self sendActionsForControlEvents:UIControlEventTouchUpOutside];
}

#pragma mark -
#pragma mark Thumb Frame

- (CGRect) thumbFrameForState:(BOOL)isOn {
    return CGRectMake(isOn ? self.bounds.size.width-self.bounds.size.height+1.0 : 1.0,
                      1.0,
                      self.bounds.size.height-2.0,
                      self.bounds.size.height-2.0);
}

#pragma mark -
#pragma mark Dealloc

- (void) dealloc {
    [_tintColor release], _tintColor = nil;
    [_onTintColor release], _onTintColor = nil;
    
    [_thumbLayer release], _thumbLayer = nil;
    [_offLayer release], _offLayer = nil;
    [_onLayer release], _onLayer = nil;
    [super dealloc];
}

@end
