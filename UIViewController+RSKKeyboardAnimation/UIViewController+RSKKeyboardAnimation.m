//
// UIViewController+RSKKeyboardAnimation.m
//
// Copyright (c) 2015 Anton Gaenko
// Copyright (c) 2015-present Ruslan Skorb, http://ruslanskorb.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "UIViewController+RSKKeyboardAnimation.h"
#import <objc/runtime.h>

static void * RSKKeyboardBeforeWillShowOrHideAnimationBlockAssociationKey = &RSKKeyboardBeforeWillShowOrHideAnimationBlockAssociationKey;
static void * RSKKeyboardWillShowOrHideAnimationBlockAssociationKey = &RSKKeyboardWillShowOrHideAnimationBlockAssociationKey;
static void * RSKKeyboardWillShowOrHideAnimationCompletionBlockAssociationKey = &RSKKeyboardWillShowOrHideAnimationCompletionBlockAssociationKey;

@implementation UIViewController (RSKKeyboardAnimation)

#pragma mark - Public API

- (void)rsk_subscribeKeyboardWithBeforeWillShowOrHideAnimation:(RSKKeyboardBeforeWillShowOrHideAnimationBlock)beforeWillShowOrHideAnimationBlock
                                       willShowOrHideAnimation:(RSKKeyboardWillShowOrHideAnimationBlock)willShowOrHideAnimationBlock
                                                    onComplete:(RSKKeyboardWillShowOrHideAnimationCompletionBlock)completionBlock
{
    // we shouldn't check for nil because it does nothing with nil
    objc_setAssociatedObject(self, RSKKeyboardBeforeWillShowOrHideAnimationBlockAssociationKey, beforeWillShowOrHideAnimationBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationBlockAssociationKey, willShowOrHideAnimationBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationCompletionBlockAssociationKey, completionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    // subscribe to keyboard animations
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rsk_handleWillShowKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rsk_handleWillHideKeyboardNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)rsk_subscribeKeyboardWithWillShowOrHideAnimation:(RSKKeyboardWillShowOrHideAnimationBlock)willShowOrHideAnimationBlock
                                              onComplete:(RSKKeyboardWillShowOrHideAnimationCompletionBlock)completionBlock
{
    [self rsk_subscribeKeyboardWithBeforeWillShowOrHideAnimation:nil willShowOrHideAnimation:willShowOrHideAnimationBlock onComplete:completionBlock];
}

- (void)rsk_unsubscribeKeyboard
{
    // remove assotiated blocks
    objc_setAssociatedObject(self, RSKKeyboardBeforeWillShowOrHideAnimationBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationCompletionBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    // unsubscribe from keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Helper Methods

- (void)rsk_handleWillShowKeyboardNotification:(NSNotification *)notification
{
    [self rsk_handleKeyboardWillShowHideNotification:notification isShowing:YES];
}

- (void)rsk_handleWillHideKeyboardNotification:(NSNotification *)notification
{
    [self rsk_handleKeyboardWillShowHideNotification:notification isShowing:NO];
}

- (void)rsk_handleKeyboardWillShowHideNotification:(NSNotification *)notification isShowing:(BOOL)isShowing
{
    // getting keyboard animation attributes
    CGRect keyboardRectEnd = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // getting passed blocks
    RSKKeyboardBeforeWillShowOrHideAnimationBlock beforeWillShowOrHideAnimationBlock = objc_getAssociatedObject(self, RSKKeyboardBeforeWillShowOrHideAnimationBlockAssociationKey);
    RSKKeyboardWillShowOrHideAnimationBlock willShowOrHideAnimationBlock = objc_getAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationBlockAssociationKey);
    RSKKeyboardWillShowOrHideAnimationCompletionBlock completionBlock = objc_getAssociatedObject(self, RSKKeyboardWillShowOrHideAnimationCompletionBlockAssociationKey);
    
    if (beforeWillShowOrHideAnimationBlock) {
        beforeWillShowOrHideAnimationBlock(keyboardRectEnd, duration, isShowing);
    }
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [UIView setAnimationCurve:curve];
                         if (willShowOrHideAnimationBlock) {
                             willShowOrHideAnimationBlock(keyboardRectEnd, duration, isShowing);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (completionBlock) {
                             completionBlock(finished, isShowing);
                         }
                     }];
}

@end
