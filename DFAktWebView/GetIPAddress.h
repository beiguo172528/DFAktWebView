//
//  GetIPAddress.h
//  Iat4
//
//  Created by DOFAR on 2020/8/29.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GetIPAddress : NSObject
+ (instancetype)Instance;
- (NSString *)getIPAddress:(BOOL)preferIPv4;
@end

NS_ASSUME_NONNULL_END
