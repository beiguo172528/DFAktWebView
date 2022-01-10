//
//  Utils.m
//  Iat4
//
//  Created by DOFAR on 2020/6/16.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import "Utils.h"

#include <dns_sd.h>
#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include<stdlib.h>


@interface Utils(){
    BOOL _isNext;
}
@property(nonatomic, assign) DNSServiceRef airplayService;
@property(nonatomic, assign) DNSRecordRef airplayRecordRef;
@property(nonatomic, assign) DNSServiceRef raopService;
@property(nonatomic, assign) DNSRecordRef raopRecordRef;

@property(nonatomic, assign) DNSServiceRef airplayService1;
@property(nonatomic, assign) DNSRecordRef airplayRecordRef1;
@property(nonatomic, assign) DNSServiceRef raopService1;
@property(nonatomic, assign) DNSRecordRef raopRecordRef1;

@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *hostName;
@end

@implementation Utils

+ (BOOL)getIsIpad{
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPad"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isStringEmpty:(NSString *)string {
    if (string == nil) {
        return YES;
    }
    if ([string length] == 0) { //string is empty or nil
        return YES;
    }
    if (![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        return YES;
    }
    return NO;
}

+ (UIColor*)gray2Color {
    return CKDarkMode? [UIColor colorWithRed:187/255.f green:187/255.f blue:187/255.f alpha:1] : [UIColor colorWithRed:0x44/255.0f green:0x44/255.0f blue:0x44/255.0f alpha:1.0f];
}
+ (UIColor*)gray4Color {
    return CKDarkMode?[UIColor colorWithRed:34.0/255.0f green:34.0/255.0f blue:34.0/255.0f alpha:1.0f]:[UIColor colorWithRed:0xDD/255.0f green:0xDD/255.0f blue:0xDD/255.0f alpha:1.0f];
}
+ (UIColor*)baseFaceGroundColor{
    return CKDarkMode?[UIColor colorWithRed:0x1e/255.0f green:0x1e/255.0f blue:0x1e/255.0f alpha:1.0f]:[UIColor whiteColor];
}
+ (UIColor*)baseBackGroundColor {
    return CKDarkMode?[UIColor colorWithRed:0x12/255.0f green:0x12/255.0f blue:0x12/255.0f alpha:1.0f]:[UIColor colorWithRed:0xEE/255.0f green:0xEE/255.0f blue:0xEE/255.0f alpha:1.0f];
}

+ (UIViewController *)getControllerFromView:(UIView*)pView{
    for (UIView *pNext = [pView superview]; pNext; pNext = pNext.superview) {
        UIResponder *pNextResponder = [pNext nextResponder];
        if ([pNextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)pNextResponder;
        }
    }
    return nil;
}

+ (BOOL)isChinese:(NSString *) str{
    for(int i=0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4E00 && a < 0x9FFF){
            return YES;
        }
    }
    return NO;
}

+ (NSString *)firstCharactor:(NSString *)aString{
    if (![Utils isChinese:aString]) {
        return aString;
    }
    NSArray *arr = [aString componentsSeparatedByString:@"-"];
    NSString *str1 = arr[0];
    //转成了可变字符串
    NSMutableString *str = [NSMutableString stringWithString:str1];
    //先转换为带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
    //再转换为不带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
    //转化为大写拼音
    NSString *pinYin = [str capitalizedString];
    NSString *tmpStr = @"";
    for (int i = 0; i < pinYin.length; i++) {
        char commitChar = [pinYin characterAtIndex:i];
        if((commitChar>64)&&(commitChar<91)){
            tmpStr = [NSString stringWithFormat:@"%@%c",tmpStr,commitChar];
        }
    }
    if([tmpStr isEqualToString:@""]){
        if(arr.count >= 2){
            return [NSString stringWithFormat:@"%@-%@",pinYin,arr[1]];
        }
        return pinYin;
    }
    else{
        if(arr.count >= 2){
            return [NSString stringWithFormat:@"%@-%@",tmpStr,arr[1]];
        }
        return tmpStr;
    }
    //获取并返回首字母
    return pinYin;
//    return [pinYin substringToIndex:1];
}

+ (NSString*)getHexStringForData:(NSData*)data{
    NSUInteger len = [data length];
    char *chars = (char *)[data bytes];
    NSMutableString *hexString = [[NSMutableString alloc]init];
    for (NSUInteger i = 0; i < len; i++) {
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx",chars[i]]];
    }
    return hexString;
}

+(UIImage*)imageFromView : (UIView*)view{
    UIGraphicsBeginImageContext(CGSizeMake(ScreenWidth,ScreenHeight));
    //renderInContext呈现接受者及其子范围到指定的上下文
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    //返回一个基于当前图形上下文的图片
    UIImage*extractImage =UIGraphicsGetImageFromCurrentImageContext();
    //移除栈顶的基于当前位图的图形上下文
    UIGraphicsEndImageContext();
    //以png格式返回指定图片的数据
    NSData*imageData =UIImagePNGRepresentation(extractImage);
    UIImage*imge = [UIImage imageWithData:imageData];
    return imge;
}

#pragma mark - 投屏相关
- (void)registerServiceName:(NSString*)name withIP:(NSString*)ip{
    NSLog(@"name:%@",name);
    NSLog(@"ip:%@",ip);
    NSDictionary *dic = @{@"name":name,@"ip":ip};
    if(self->_isNext){
        [self performSelector:@selector(registerServiceDic:) withObject:dic afterDelay:5];
        return;
    }
    self->_isNext = true;
    [self registerServiceDic:dic];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5), dispatch_get_main_queue(), ^{
        self->_isNext = false;
    });
}

- (void)registerServiceDic:(NSDictionary*)dic{
    NSString *name = dic[@"name"];
    NSString *ip = dic[@"ip"];
    if(!ip || [ip isEqualToString:@""]){
        return;
    }
    if(!self.deviceID || [self.deviceID isEqualToString:@""]){
        self.deviceID = @"6c:5a:b5:63:70:01";
    }
    else{
        NSString *lastString = [self.deviceID substringFromIndex:self.deviceID.length-1];
        self.deviceID = [self.deviceID substringToIndex:self.deviceID.length-1];
        int num = lastString.intValue;
        if(num >= 9){
            num = 0;
        }
        else{
            num += 1;
        }
        self.deviceID = [NSString stringWithFormat:@"%@%d",self.deviceID,num];
    }
    if(!self.hostName || [self.hostName isEqualToString:@""]){
        self.hostName = @"dair.local";
    }
    else{
        NSArray *arr = [self.hostName componentsSeparatedByString:@"."];
        NSString *str = arr[0];
        NSString *lastString = [str substringFromIndex:str.length-1];
        int num = lastString.intValue;
        num += 1;
        NSString *str1 = [str substringToIndex:str.length-1];
        self.hostName = [NSString stringWithFormat:@"%@%d.%@",str1,num,arr[1]];
    }
    NSString *serverName = [name  isEqual: @""] ? @"DoFar" : name;
    [self createAirplayServiceWithDeviceID:self.deviceID withName:serverName withHost:self.hostName withPort:7000 withIP:ip];
    [self createRaopServiceWithName:[NSString stringWithFormat:@"%@@%@",self.deviceID,serverName] withHost:self.hostName withPort:5000 withIP:ip withBaseName:serverName];
}

- (void)removeRecordService{
    if(self.raopService && self.airplayService){
        DNSServiceRemoveRecord(self.airplayService, self.airplayRecordRef, kDNSServiceFlagsDefault);
        DNSServiceRemoveRecord(self.raopService, self.raopRecordRef, kDNSServiceFlagsDefault);
        self.raopService = nil;
        self.airplayService = nil;
        self.raopRecordRef = nil;
        self.airplayRecordRef = nil;
    }
    else if(self.raopService1 && self.airplayService1){
        DNSServiceRemoveRecord(self.airplayService1, self.airplayRecordRef1, kDNSServiceFlagsDefault);
        DNSServiceRemoveRecord(self.raopService1, self.raopRecordRef1, kDNSServiceFlagsDefault);
        self.raopService1 = nil;
        self.airplayService1 = nil;
        self.raopRecordRef1 = nil;
        self.airplayRecordRef1 = nil;
    }
    self->_isNext = false;
}

- (void)createAirplayServiceWithDeviceID:(NSString*)deviceID withName:(NSString*)name withHost:(NSString*)host withPort:(int)port withIP:(NSString*)ip{
    DNSServiceRef airplayService = NULL;
    NSDictionary *videoTXTDict = @{
        @"rmodel":@"Android1,0",
        @"srcvers": @"220.68",
        @"pi":@"b08f5a79-db29-4384-b456-a4784d9e6055",
        @"deviceid": deviceID,
        @"vv": @"2",
        @"model": @"AppleTV3,2",
        @"flags": @"0x4",
        @"features": @"0x5A7FFFF7,0x1E",
        @"pk": @"ea4166cf03a89f6d3c7b0c447d3153a6ca777e2843128832a2fb8dadeb37e629",
    };
    TXTRecordRef videoTXTRecord;
    TXTRecordCreate(&videoTXTRecord, 0, NULL);
    for (id key in videoTXTDict.allKeys) {
        TXTRecordSetValue(&videoTXTRecord, [key UTF8String], strlen([videoTXTDict[key] UTF8String]), [videoTXTDict[key] UTF8String]);
    }
    char str[80];
    const char * c1 =[name UTF8String];
    strcpy(str, c1);
    strcat(str, "._airplay._tcp.local");
    DNSServiceRegister(&airplayService, 0, kDNSServiceInterfaceIndexLocalOnly, [name UTF8String], "_airplay._tcp", NULL, str, htons(port), TXTRecordGetLength(&videoTXTRecord), TXTRecordGetBytesPtr(&videoTXTRecord), NULL, NULL);
    NSArray *IPComponents = [ip componentsSeparatedByString:@"."];
    char rawData[5] = {0};
    sprintf(rawData, "%c%c%c%c", (char)[IPComponents[0] integerValue], (char)[IPComponents[1] integerValue], (char)[IPComponents[2] integerValue], (char)[IPComponents[3] integerValue]);
    DNSRecordRef recordRef = NULL;
    DNSServiceAddRecord(airplayService, &recordRef, kDNSServiceFlagsDefault, kDNSServiceType_A, strlen(rawData), rawData, 0);
    if(!self.airplayService){
        self.airplayService = airplayService;
        self.airplayRecordRef = recordRef;
    }
    else{
        self.airplayService1 = airplayService;
        self.airplayRecordRef1 = recordRef;
    }
}

- (void)createRaopServiceWithName:(NSString*)name withHost:(NSString*)host withPort:(int)port withIP:(NSString*)ip withBaseName:(NSString*)baseName{
    DNSServiceRef raopService = NULL;
    NSDictionary *raopTXTDict = @{
        @"txtvers":@"1",
        @"ch":@"2",
        @"cn":@"0,1,3",
        @"et":@"0,3,5",
        @"sv":@"false",
        @"da":@"true",
        @"sr":@"44100",
        @"ss":@"16",
        @"vn":@"3",
        @"tp":@"UDP",
        @"md":@"0,1,2",
        @"vs":@"130.14",
        @"sm":@"false",
        @"ek":@"1",
        @"sf":@"0x4",
        @"am":@"Shairport,1",
        @"pk":@"ea4166cf03a89f6d3c7b0c447d3153a6ca777e2843128832a2fb8dadeb37e629"
    };
    TXTRecordRef raopTXTRecord;
    TXTRecordCreate(& raopTXTRecord, 0, NULL);
    for (id key in raopTXTDict.allKeys) {
        TXTRecordSetValue(& raopTXTRecord, [key UTF8String], strlen([raopTXTDict[key] UTF8String]), [raopTXTDict[key] UTF8String]);
    }
    char str[80];
    const char * c1 =[baseName UTF8String];
    strcpy(str, c1);
    strcat(str, "._airplay._tcp.local");
    DNSServiceRegister(&raopService, 0, kDNSServiceInterfaceIndexLocalOnly, [name UTF8String], "_raop._tcp", NULL, str, htons(port), TXTRecordGetLength(&raopTXTRecord), TXTRecordGetBytesPtr(&raopTXTRecord), NULL, NULL);
    NSArray *IPComponents = [ip componentsSeparatedByString:@"."];
    char rawData[5];
    sprintf(rawData, "%c%c%c%c", (char)[IPComponents[0] integerValue], (char)[IPComponents[1] integerValue], (char)[IPComponents[2] integerValue], (char)[IPComponents[3] integerValue]);
    DNSRecordRef recordRef = NULL;
    DNSServiceAddRecord(raopService, &recordRef, kDNSServiceFlagsDefault, kDNSServiceType_A, strlen(rawData), rawData, 0);
    if(!self.raopService){
        self.raopService = raopService;
        self.raopRecordRef = recordRef;
    }
    else{
        self.raopService1 = raopService;
        self.raopRecordRef1 = recordRef;
    }
}

- (void)removeRecordRaopServiceWithName:(NSString*)name withPort:(int)port withBaseName:(NSString*)baseName{
    DNSServiceRef raopService = NULL;
    NSDictionary *raopTXTDict = @{
        @"txtvers":@"1",
        @"ch":@"2",
        @"cn":@"0,1,3",
        @"et":@"0,3,5",
        @"sv":@"false",
        @"da":@"true",
        @"sr":@"44100",
        @"ss":@"16",
        @"vn":@"3",
        @"tp":@"UDP",
        @"md":@"0,1,2",
        @"vs":@"130.14",
        @"sm":@"false",
        @"ek":@"1",
        @"sf":@"0x4",
        @"am":@"Shairport,1",
        @"pk":@"ea4166cf03a89f6d3c7b0c447d3153a6ca777e2843128832a2fb8dadeb37e629"
    };
    TXTRecordRef raopTXTRecord;
    TXTRecordCreate(& raopTXTRecord, 0, NULL);
    for (id key in raopTXTDict.allKeys) {
        TXTRecordSetValue(& raopTXTRecord, [key UTF8String], strlen([raopTXTDict[key] UTF8String]), [raopTXTDict[key] UTF8String]);
    }
    char str[80];
    const char * c1 =[baseName UTF8String];
    strcpy(str, c1);
    strcat(str, "._airplay._tcp.local");
    DNSServiceRegister(&raopService, 0, kDNSServiceInterfaceIndexLocalOnly, [name UTF8String], "_raop._tcp", NULL, str, htons(port), TXTRecordGetLength(&raopTXTRecord), TXTRecordGetBytesPtr(&raopTXTRecord), NULL, NULL);
    DNSRecordRef recordRef = NULL;
    DNSServiceRemoveRecord(raopService, recordRef, kDNSServiceFlagsDefault);
}

+ (NSString *)getCurrentTimestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0]; // 获取当前时间0秒后的时间
    NSTimeInterval time = [date timeIntervalSince1970]*1000;// *1000 是精确到毫秒(13位),不乘就是精确到秒(10位)
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}
/**
 SSZipArchive解压

 @param path 压缩包文件路径
 */
//+ (NSString*)uSSZipArchiveWithFilePath:(NSString *)path withCover:(BOOL)isCover{
//    //Caches路径
//    NSString *savepath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    //解压目标路径
//    NSString *destinationPath =[savepath stringByAppendingPathComponent:@"SSZipArchive"];
//    if(!isCover){
//        BOOL isDir = false;
//        if([[NSFileManager defaultManager]fileExistsAtPath:destinationPath isDirectory:&isDir]){
//            return [destinationPath stringByAppendingPathComponent:@"dist/index.html"];
//        }
//    }
//    //解压
//    NSError *error;
//    NSString *destinationPath1 =[savepath stringByAppendingPathComponent:@"SSZipArchive1"];
//    if([SSZipArchive unzipFileAtPath:path toDestination:destinationPath1 overwrite:YES password:nil error:&error]){
//        BOOL isDir = false;
//        [[NSFileManager defaultManager]fileExistsAtPath:destinationPath isDirectory:&isDir];
//        if(isDir){
//            NSError *err;
//            [[NSFileManager defaultManager]removeItemAtPath:destinationPath error:&err];
//            if(!err){
//                NSError *isError;
//                [[NSFileManager defaultManager]moveItemAtPath:destinationPath1 toPath:destinationPath error:&isError];
//                if(!isError){
//                    return [destinationPath stringByAppendingPathComponent:@"dist/index.html"];
//                }
//            }
//        }
//        NSError *isError;
//        [[NSFileManager defaultManager]moveItemAtPath:destinationPath1 toPath:destinationPath error:&isError];
//        if(!isError){
//            return [destinationPath stringByAppendingPathComponent:@"dist/index.html"];
//        }else{
//            return [destinationPath1 stringByAppendingPathComponent:@"dist/index.html"];
//        }
//    }
//    return @"";
//}

+ (void)printVersion{
    NSString *savepath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *destinationPath =[savepath stringByAppendingPathComponent:@"SSZipArchive"];
    NSString *str1 = [destinationPath stringByAppendingPathComponent:@"dist/config.json"];
    NSString *str2 = [NSString stringWithContentsOfFile:str1 encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"printVersion：%@",str2);
}

+ (void)deleteWebCache {
//allWebsiteDataTypes清除所有缓存
    NSArray * types=@[WKWebsiteDataTypeDiskCache,WKWebsiteDataTypeOfflineWebApplicationCache,WKWebsiteDataTypeMemoryCache];
        
    NSSet *websiteDataTypes= [NSSet setWithArray:types];

    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];

    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        
    }];
}
//删除缓存文件
+ (void)clearCache{
    NSString *imageDir = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), @"IMGS"];
    [[NSFileManager defaultManager] removeItemAtPath:imageDir error:nil];
}

+ (NSDictionary*)dictionaryWithJsonString:(NSString*)jsonString{
    if(jsonString == nil){
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

+ (BOOL)isValidIP:(NSString *)ipStr {
    if (nil == ipStr) {
        return NO;
   }

    NSArray *ipArray = [ipStr componentsSeparatedByString:@"."];
    if (ipArray.count == 4) {
        for (NSString *ipnumberStr in ipArray) {
             if ([self isPureInt:ipnumberStr]) {
                 int ipnumber = [ipnumberStr intValue];
                 if (!(ipnumber>=0 && ipnumber<=255)) {
                     return NO;
                 }
            }
        }
        return YES;
    }
    return NO;
}

//是否整形
+ (BOOL)isPureInt:(NSString*)string {
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}


@end
