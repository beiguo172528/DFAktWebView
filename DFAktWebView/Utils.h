//
//  Utils.h
//  Iat4
//
//  Created by DOFAR on 2020/6/16.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define BECOME_ACTIVE @"BECOME_ACTIVE"
#define CREATE_MEDIA_PLAYER @"CREATE_MEDIA_PLAYER"

#define VIEWSAFEAREAINSETS(view) ({UIEdgeInsets i; if(@available(iOS 11.0, *)) {i = view.safeAreaInsets;} else {i = UIEdgeInsetsMake(20, 0, 0, 0);} i;})

#define AppID @"1527513227"
#define kBuyerAppUpdateUrl @"https://itunes.apple.com/cn/app/id1527513227?mt=8"
#define CKDarkMode ({BOOL isDark; if(@available(iOS 13.0, *)) {isDark = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;} else {isDark = NO;}isDark;})


typedef NS_ENUM(NSUInteger, LiveType) {
    LiveTypeNone,
    LiveTypeSmall,
    LiveTypeNomal,
    LiveTypeBig,
    LiveTypeClose,
};

typedef NS_ENUM(NSInteger,LessonLiveType) {
    LessonLiveTypeNone,
    LessonLiveTypeLive,
    LessonLiveTypeKzkt,
};

@interface Utils : NSObject
+ (BOOL)getIsIpad;
+ (BOOL)isStringEmpty:(NSString *)string;
+ (UIColor*)gray2Color;
+ (UIColor*)gray4Color;
+ (UIColor*)baseFaceGroundColor;
+ (UIColor*)baseBackGroundColor;
+ (UIViewController *)getControllerFromView:(UIView*)pView;
+ (NSString *)firstCharactor:(NSString *)aString;
+ (NSString*)getHexStringForData:(NSData*)data;
//截屏
+(UIImage*)imageFromView:(UIView*)view;
// 投屏相关
- (void)registerServiceName:(NSString*)name withIP:(NSString*)ip;
- (void)removeRecordService;
//zip解压
//+ (NSString*)uSSZipArchiveWithFilePath:(NSString *)path withCover:(BOOL)isCover;
+ (void)deleteWebCache;
+ (void)printVersion;
//删除缓存文件
+ (void)clearCache;
+ (NSDictionary*)dictionaryWithJsonString:(NSString*)jsonString;
+ (BOOL)isValidIP:(NSString *)ipStr;
@end

NS_ASSUME_NONNULL_END
