//
//  DocumentViewController.h
//  Iat4
//
//  Created by DOFAR on 2020/6/16.
//  Copyright © 2020 DOFAR. All rights reserved.
//

//#import "ViewController.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DocumentViewControllerDelegate <NSObject>

- (void)readTime:(int)num;

@end

@interface DocumentViewController : UIViewController
@property(nonatomic, weak) id<DocumentViewControllerDelegate> delegate;
@property(nonatomic, copy) NSString* fileUrl;
@property(nonatomic, assign) BOOL isCanOtherOpen;
@end

NS_ASSUME_NONNULL_END
