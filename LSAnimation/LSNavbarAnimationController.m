//
//  LSNavbarAnimationController.m
//  需求：
//  1、
//
//  Created by baidu on 2017/12/26.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "LSNavbarAnimationController.h"
#import "UIView+LayoutMethods.h"


@import WebKit;

@interface LSNavbarAnimationController ()<WKNavigationDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UIView * topFixedView;
@property (nonatomic,strong) UIView *maskView;
@property (nonatomic,strong) WKWebView * bottomScrollView;
@property (nonatomic,strong) UIPanGestureRecognizer *panGes;
@property (nonatomic,assign) BOOL animationing;
@end

@implementation LSNavbarAnimationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.topFixedView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.bottomScrollView];
    self.bottomScrollView.scrollView.scrollEnabled = NO;
    
    self.topFixedView.frame = CGRectMake(0, 0, self.view.ct_width, 300);
    self.bottomScrollView.ct_top = self.topFixedView.ct_bottom;
    self.bottomScrollView.ct_left = self.topFixedView.ct_left;
    self.bottomScrollView.ct_width = self.topFixedView.ct_width;
    self.bottomScrollView.ct_height = self.view.ct_height - self.topFixedView.ct_height;
//    self.bottomScrollView.scrollView.contentSize = CGSizeMake(self.bottomScrollView.ct_width, 1000);
    self.maskView.frame = self.topFixedView.frame;
    // 添加手势
    [self.bottomScrollView addGestureRecognizer:self.panGes];
    self.navigationController.navigationBar.hidden = YES;
    // 设置手势优先级处理手势冲突：当是两个自己定义的手势会好，因为scrollview，你不知道里面还有什么其他手势
//    [self.bottomScrollView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.panGes];
    
    [self.bottomScrollView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
   
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation{
    
    [self.bottomScrollView evaluateJavaScript:@"document.body.offsetHeight"completionHandler:^(id _Nullable result,NSError * _Nullable error) {
        
        //获取页面高度，并重置webview的frame
        CGFloat height = [result doubleValue];
        CGRect frame = self.bottomScrollView.frame;
        frame.size.height = height;
        self.bottomScrollView.frame = frame;
    }];
    
}
#pragma mark - gesture
- (void)pan:(UIPanGestureRecognizer *)pan {
    
    CGPoint panPoint = [pan translationInView:self.bottomScrollView];
    CGFloat upcenterPointY = (self.topFixedView.ct_height )/2.0 + 64;
    CGFloat downcenterPointY = (self.topFixedView.ct_height )/2.0;


    NSLog(@"panPoint.y = %f",panPoint.y);
 
    if(pan.state == UIGestureRecognizerStateBegan) {
        self.animationing = NO;
    }
    else if (pan.state == UIGestureRecognizerStateChanged) {
        
        // 判断边界
        // 如果大于frame或者64，则不能响应手势，return
        if (self.bottomScrollView.ct_top <= 64 && panPoint.y < 0) {
            return;
        }
        if (self.bottomScrollView.ct_top >= self.topFixedView.ct_bottom && panPoint.y > 0) {
            return;
        }
        
        // 可以跟手移动
        CGFloat y = self.bottomScrollView.ct_top + panPoint.y;
        [self.bottomScrollView setFrame:CGRectMake(0, y, self.view.ct_width, self.bottomScrollView.ct_height - panPoint.y)];
        // 因为拖动起来一直是在递增，所以每次都要用setTranslation:方法制0这样才不至于不受控制般滑动出视图
        [pan setTranslation:CGPointMake(0, 0) inView:self.bottomScrollView];
        
        CGFloat alpha = (self.topFixedView.ct_bottom-self.bottomScrollView.ct_top)/(upcenterPointY);;
        NSLog(@"alpha = %f",alpha);
        self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ABS(alpha)];
        
        // 如果在原来的frame和64之间，往上滚动滚动，滚到/2.0的地方，需要回到64，,如果往下滚动，小于这个地方，滚回到原处，动画,其他都要跟手移动
       
        if (panPoint.y < 0 && self.bottomScrollView.ct_top <= upcenterPointY) {
            [self moveToTopAnimated];
            self.animationing = YES;
            self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
            return;
        }
        if (panPoint.y > 0 && self.bottomScrollView.ct_top > downcenterPointY) {
            [self moveToOriginalAnimated];
            self.animationing = YES;
            self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];

            return;
        }
    }
    else if (pan.state == UIGestureRecognizerStateEnded) {

        if (self.animationing) {
            self.animationing = NO;
            return ;
        }
        // 停下跟在上面边界判断一样，需要复位
        if (self.bottomScrollView.ct_top <= 64 && panPoint.y < 0) {
            return;
        }
        if (self.bottomScrollView.ct_top >= self.topFixedView.ct_bottom && panPoint.y > 0) {
            return;
        }
        if (self.bottomScrollView.ct_top > upcenterPointY) {
            [self moveToOriginalAnimated];
        }
        else if (self.bottomScrollView.ct_top < downcenterPointY) {
            [self moveToTopAnimated];
        }
    }
}

- (void)moveToTopAnimated {
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:1 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState animations:^{
        // 动画期间，禁用操作
        self.bottomScrollView.userInteractionEnabled = NO;
        // 设置目标位置
        [self.bottomScrollView setFrame:CGRectMake(0, 64, self.view.ct_width, self.view.ct_height)];
    } completion:^(BOOL finished) {
        // 动画结束，
        self.bottomScrollView.userInteractionEnabled = YES;
        self.bottomScrollView.scrollView.scrollEnabled = YES;
    }];
    
    self.navigationController.navigationBar.hidden = NO;
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.4f;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.fillMode = kCAFillModeForwards;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromBottom;
    [self.navigationController.navigationBar.layer addAnimation:animation forKey:nil];

}


- (void)moveToOriginalAnimated {
    // 动画
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState animations:^{
        // 动画期间，禁用操作
        self.bottomScrollView.userInteractionEnabled = NO;
        // 设置目标位置
        [self.bottomScrollView setFrame:CGRectMake(0, self.topFixedView.ct_bottom, self.view.ct_width, self.view.ct_height-self.topFixedView.ct_bottom)];
    } completion:^(BOOL finished) {
        // 动画结束，
        self.bottomScrollView.userInteractionEnabled = YES;
        self.bottomScrollView.scrollView.scrollEnabled = YES;
    }];
    
    self.navigationController.navigationBar.hidden = YES;
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.4f;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.fillMode = kCAFillModeForwards;
    animation.subtype = kCATransitionFromTop;
    [animation setType:kCATransitionReveal];
    
    [self.navigationController.navigationBar.layer addAnimation:animation forKey:nil];
}

#pragma mark - getters & setters
- (UIView *)topFixedView {
    if (_topFixedView == nil) {
        _topFixedView = [UIView new];
        _topFixedView.backgroundColor = [UIColor grayColor];
    }
    return _topFixedView;
}

- (UIView *)maskView {
    if (_maskView == nil) {
        _maskView = [UIView new];
        _maskView.backgroundColor = [UIColor clearColor];
    }
    return _maskView;
}

- (WKWebView *)bottomScrollView {
    if (_bottomScrollView == nil) {
        _bottomScrollView = [[WKWebView alloc] initWithFrame:CGRectZero];
        _bottomScrollView.navigationDelegate = self;
        _bottomScrollView.scrollView.bounces = false;
    }
    return _bottomScrollView;
}

- (UIPanGestureRecognizer *)panGes {
    if (_panGes == nil) {
        _panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        _panGes.delegate = self;
    }
    return _panGes;
}
#pragma mark - 手势冲突处理
// 处理手势冲突

// 优先处理手势优先级
// 询问是否这个手势是通过一个指定手势的触发才失败
// 前面手势的优先级，要比后面的高，返回YES
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.panGes == gestureRecognizer) {
        return YES;
    }
    return YES;
}

// 因为两个手势不可以同时识别，所以不实现这个,不能完全控制
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

// 是不是要响应手势，好像都需要响应手势，需要在状态中判断
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if (gestureRecognizer == self.panGes) {
        // 当scrollview在顶部，如果是contentOffset > 0 有位移，当他有偏移量不需要响应手势，如果没有偏移量，则需要响应手势
        // 当scrollview在顶部，如果是contentOffset <= 0 无位移，需要响应手势
        // 但是这里屏蔽不掉里面本身有可以处理事件的情况，比如里面可以点击，可以有别的手势，需要在下面的过程中判断
        if (self.bottomScrollView.scrollView.contentOffset.y > 0) {
            return NO;
        }
    }
    return YES;
}

// 具体要判断是否要响应手势
// 响应之后状态判断，这里是在滑动的过程中，手势pan有状态，在移动
// 手势在move过程中，如果到达顶部，继续往上滑动，则不响应手势
// 手势在move过程中，如果到达顶部，继续向下滑动，则应该响应手势
// 手势在move过程中，如果到达底部，继续向下滑动，则不响应手势
// 手势在move过程中，如果到达底部，继续向上滑动，则响应手势
// 其他都要响应YES
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGes) {
//        if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
        // 移动距离
        CGPoint panPoint = [self.panGes translationInView:self.bottomScrollView];
        BOOL isMoveUp = panPoint.y <=0 ? YES:NO;

        // 手势在move过程中，如果到达顶部，继续往上滑动，则不响应手势
        if (self.bottomScrollView.ct_top == 64 && isMoveUp ) {
            return NO;
        }
        
        // 手势在move过程中，如果到达顶部，继续向下滑动，则应该响应手势
        if (self.bottomScrollView.ct_top == 64 && !isMoveUp) {
            return YES;
        }
        
        // 手势在move过程中，如果到达底部，继续向下滑动，则不响应手势
        if (self.bottomScrollView.ct_top == self.topFixedView.ct_bottom && !isMoveUp) {
            return NO;
        }
        if (self.bottomScrollView.ct_top == self.topFixedView.ct_bottom && isMoveUp) {
            return YES;
        }
        return YES;
//        }
    }
    return YES;
}


@end
