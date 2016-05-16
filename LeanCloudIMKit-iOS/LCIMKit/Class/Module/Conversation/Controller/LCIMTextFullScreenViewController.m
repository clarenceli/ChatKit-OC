//
//  LCIMTextFullScreenViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/23.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMTextFullScreenViewController.h"
#import "CYLDeallocBlockExecutor.h"
#import "LCIMFaceManager.h"
#define kLCIMTextFont [UIFont systemFontOfSize:30.0f]
static void * const LCIMTextFullScreenViewContentSizeContext = (void*)&LCIMTextFullScreenViewContentSizeContext;

@interface LCIMTextFullScreenViewController()

@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UITextView *displayTextView;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy, readonly) NSDictionary *textStyle;
@property (nonatomic, copy) LCIMRemoveFromWindowHandler removeFromWindowHandler;
@end

@implementation LCIMTextFullScreenViewController
@synthesize textStyle = _textStyle;

- (UITextView *)displayTextView {
    if (!_displayTextView) {
        UITextView *displayTextView = [[UITextView alloc] initWithFrame:self.view.frame];
        [displayTextView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:LCIMTextFullScreenViewContentSizeContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self cyl_executeAtDealloc:^{
            [displayTextView removeObserver:weakSelf forKeyPath:@"contentSize"];
        }];
        displayTextView.contentSize = self.view.bounds.size;
        displayTextView.textColor = [UIColor blackColor];
        displayTextView.editable = NO;
        displayTextView.backgroundColor = [UIColor whiteColor];
        displayTextView.dataDetectorTypes = UIDataDetectorTypeAll;
        displayTextView.textContainerInset = UIEdgeInsetsMake(0,20,0,20);
        [self.backgroundView addSubview:displayTextView];
        _displayTextView = displayTextView;
    }
    return _displayTextView;
}

- (NSDictionary *)textStyle {
    if (!_textStyle) {
        UIFont *font = kLCIMTextFont;
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;
        style.paragraphSpacing = 0.25 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        _textStyle = @{NSFontAttributeName: font,
                       NSParagraphStyleAttributeName: style};
    }
    return _textStyle;
}
/**
 *  lazy load backgroundView
 *
 *  @return UIView
 */
- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
        backgroundView.backgroundColor = [UIColor blueColor];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromWindow:)];
        [backgroundView addGestureRecognizer:recognizer];
        [self.view addSubview:backgroundView];
        _backgroundView = backgroundView;
    }
    return _backgroundView;
}

- (void)setRemoveFromWindowHandler:(LCIMRemoveFromWindowHandler)removeFromWindowHandler {
    _removeFromWindowHandler = removeFromWindowHandler;
}

- (void)removeFromWindow:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self.navigationController popViewControllerAnimated:NO];
    !_removeFromWindowHandler ?: _removeFromWindowHandler();
}

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (!self) {
        return nil;
    }
    _text = text;
    NSMutableAttributedString *attrS = [LCIMFaceManager emotionStrWithString:text];
    [attrS addAttributes:self.textStyle range:NSMakeRange(0, attrS.length)];
    self.displayTextView.attributedText = attrS;
    
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Life cycle

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCIMTextFullScreenViewContentSizeContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCIMTextFullScreenViewContentSizeContext) {
        UITextView *textView = object;
        CGFloat topCorrect = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        [textView setContentInset:UIEdgeInsetsMake(topCorrect,0,0,0)];
    }
}

@end