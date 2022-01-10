//
//  DFWebView.h
//  DFAktWebView
//
//  Created by DOFAR on 2022/1/7.
//

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DFWebView : UIViewController
- (void)load:(NSString*)url;
@end

NS_ASSUME_NONNULL_END
