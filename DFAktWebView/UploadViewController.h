//
//  UploadViewController.h
//  Iat4
//
//  Created by DOFAR on 2020/8/12.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol UploadViewControllerDelegate <NSObject>

-(void)uploadEndPath:(NSString*)path;

@end

@interface UploadViewController : UIViewController
@property(nonatomic, copy) NSString *updateStr;
@property(nonatomic, assign) BOOL isUp;
@property(nonatomic, weak) id<UploadViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
