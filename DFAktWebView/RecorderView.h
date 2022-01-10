//
//  RecorderView.h
//  Iat4
//
//  Created by DOFAR on 2020/7/13.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RecorderViewDelegate <NSObject>

- (void)recordEndWithData:(NSDictionary*)dic;
- (void)recordEndWithPath:(NSString*)path;

@end

@interface RecorderView : UIView
@property (nonatomic, weak) id<RecorderViewDelegate> delegate;
- (void)touch;
@end

NS_ASSUME_NONNULL_END
