//
//  DFWebView.m
//  DFAktWebView
//
//  Created by DOFAR on 2022/1/7.
//

#import "Utils.h"
#import "Masonry.h"
#import "WebViewC.h"
#import "DFWebView.h"
#import "Reachability.h"
#import "RecorderView.h"
#import "GetIPAddress.h"
#import "SVProgressHUD.h"
#import "WebViewJavascriptBridge/WebViewJavascriptBridge.h"
#import "QRCodeScannerController.h"
#import "DocumentViewController.h"
#import "UploadViewController.h"
#import <WebKit/WebKit.h>
#import <CoreLocation/CoreLocation.h>

@interface DFWebView()<WKUIDelegate,WKNavigationDelegate,DocumentViewControllerDelegate,RecorderViewDelegate,UploadViewControllerDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate>{
    NSString *fileUrl;
}
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@property (nonatomic, strong) RecorderView *recorderView;
@property (nonatomic, strong) UIImageView *popImgV;
@property (nonatomic, strong) CLLocation *location;
@end

@implementation DFWebView

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(self.navigationController){
        [self.navigationController.navigationBar setHidden:true];
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(self.navigationController){
        [self.navigationController.navigationBar setHidden:false];
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNotification];
    [self createRecorderView];
    [self createWebV];
    [self initLocationService];
    [self registerHandlers];
    if(self->fileUrl && ![self->fileUrl isEqualToString:@""]){
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self->fileUrl]]];
    }
}

- (void)didReceiveMemoryWarning{
    NSLog(@"内存问题");
}

- (void)load:(NSString*)url{
    self->fileUrl = url;
    if(self.webView){
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
}

#pragma mark - webview

- (void)createRecorderView{
    self.recorderView = [[RecorderView alloc]init];
    self.recorderView.frame = CGRectMake(0, (ScreenHeight - 150), ScreenWidth, 150);
    [self.view addSubview:self.recorderView];
    [self.recorderView setHidden:true];
    self.recorderView.delegate = self;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)createWebV{
    if(!self.webView){
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    config.preferences.javaScriptEnabled = true;
    config.allowsInlineMediaPlayback = true;
    NSLog(@"height:%f",[UIApplication sharedApplication].statusBarFrame.size.height);
    float height = [UIApplication sharedApplication].statusBarFrame.size.height;
    self.webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, height, ScreenWidth, ScreenHeight - height) configuration:config];
    self.webView.scrollView.bounces = false;
    [self.webView setOpaque:false];
    self.webView.scrollView.showsVerticalScrollIndicator = false;
    self.webView.scrollView.showsHorizontalScrollIndicator = false;
    [self.webView.scrollView setScrollEnabled:true];
    self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.webView setUIDelegate:self];
    [self.webView setNavigationDelegate:self];
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top);
        make.bottom.equalTo(self.view.mas_bottom);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
    }];
}

- (void)registerHandlers{
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.bridge setWebViewDelegate:self];
    [self.bridge registerHandler:@"getFuncs" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *funcs = @"getFuncs,getHeaderHeight,scan,openDocument,lessonBegin,lessonEnd,clearCache,showAudio,hiddenAudio,getLocalInfo,getSystemVersion,showBack,getDeviceInfo,downLoad,downLoadBase64,toWeb,getLocation";
        responseCallback(funcs);
    }];
    [self.bridge registerHandler:@"getHeaderHeight" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (@available(iOS 13.0, *)) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (!window) {
                responseCallback(@(window.windowScene.statusBarManager.statusBarFrame.size.height));
            }
        }
        else {
            responseCallback(@(UIApplication.sharedApplication.statusBarFrame.size.height));
        }
    }];
    [self.bridge registerHandler:@"scan" handler:^(id data, WVJBResponseCallback responseCallback) {
        QRCodeScannerController *vc = [[QRCodeScannerController alloc]init];
        vc.succScanner = ^(NSString* _Nullable scanStr){
            responseCallback(scanStr);
        };
        vc.errScanner = ^(NSString * _Nullable errStr) {
            responseCallback(errStr);
        };
        if(self.navigationController){
            [self.navigationController pushViewController:vc animated:true];
        }
    }];
    [self.bridge registerHandler:@"openDocument" handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback(@(UIApplication.sharedApplication.statusBarFrame.size.height));
        NSString *fileUrl = data;
        DocumentViewController *dvc = [[DocumentViewController alloc]init];
        NSArray *arr = [fileUrl componentsSeparatedByString:@"&"];
        dvc.fileUrl = arr[0];
        bool allowDownload = false;
        for (NSString *item in arr) {
            if ([item containsString:@"allowDownload"]) {
                allowDownload = [[item substringFromIndex:item.length-1] isEqualToString:@"Y"];
            }
        }
        dvc.isCanOtherOpen = allowDownload;
        dvc.delegate = self;
        if(self.navigationController){
            [self.navigationController pushViewController:dvc animated:true];
        }
    }];
    [self.bridge registerHandler:@"lessonBegin" handler:^(id data, WVJBResponseCallback responseCallback) {
        [UIApplication sharedApplication].idleTimerDisabled = true;
    }];
    [self.bridge registerHandler:@"lessonEnd" handler:^(id data, WVJBResponseCallback responseCallback) {
        [UIApplication sharedApplication].idleTimerDisabled = false;
    }];
    [self.bridge registerHandler:@"clearCache" handler:^(id data, WVJBResponseCallback responseCallback) {
        [self clearCache];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"UserName"];
    }];
    [self.bridge registerHandler:@"showAudio" handler:^(id data, WVJBResponseCallback responseCallback) {
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"Token"];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"URL"];
        [self showAudio];
        NSString *string = data;
        NSArray *arraySubstrings = [string componentsSeparatedByString:@"###"];
        NSString *token = arraySubstrings.firstObject;
        NSString *url = arraySubstrings.lastObject;
        [[NSUserDefaults standardUserDefaults]setObject:token forKey:@"Token"];
        [[NSUserDefaults standardUserDefaults]setObject:url forKey:@"URL"];
    }];
    [self.bridge registerHandler:@"hiddenAudio" handler:^(id data, WVJBResponseCallback responseCallback) {
        [self hiddenAudio];
    }];
    [self.bridge registerHandler:@"getLocalInfo" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dic = @{@"ip":[[GetIPAddress Instance] getIPAddress:true]};
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
        NSString *str = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        responseCallback(str);
    }];
    [self.bridge registerHandler:@"getSystemVersion" handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback([[UIDevice currentDevice] systemVersion]);
    }];
    [self.bridge registerHandler:@"showBack" handler:^(id data, WVJBResponseCallback responseCallback) {
        [self popAnimate];
    }];
    [self.bridge registerHandler:@"getDeviceInfo" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
        if(deviceToken && ![deviceToken isEqualToString:@""]){
            NSDictionary *dic = @{@"id":deviceToken,@"type":@(29005)};
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
            NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
            responseCallback(jsonString);
        }
    }];
    [self.bridge registerHandler:@"downLoad" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *str= data;
        UploadViewController *vc = [[UploadViewController alloc]init];
        vc.delegate = self;
        vc.updateStr = str;
        vc.isUp = false;
        if(self.navigationController){
            [self.navigationController pushViewController:vc animated:true];
        }
    }];
    [self.bridge registerHandler:@"downLoadBase64" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *str = data;
        NSArray *imageArray = [str componentsSeparatedByString:@","];
        NSData *imageData = [[NSData alloc]initWithBase64EncodedString:imageArray[1] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *img = [[UIImage alloc]initWithData:imageData];
        UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }];
    [self.bridge registerHandler:@"toWeb" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *str = data;
        WebViewC *wvc = [[WebViewC alloc]init];
        wvc.gotoUrl = str;
        if(self.navigationController){
            [self.navigationController pushViewController:wvc animated:true];
        }
    }];
    [self.bridge registerHandler:@"getLocation" handler:^(id data, WVJBResponseCallback responseCallback) {
        float latitude = 0.0;
        float longitude = 0.0;
        if(self.location){
            latitude = self.location.coordinate.latitude;
            longitude = self.location.coordinate.longitude;
        }
        NSDictionary *dic = @{@"latitude":@(latitude),@"longitude":@(longitude)};
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
        NSString *str = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        responseCallback(str);
    }];
    [self.bridge registerHandler:@"getUserAgreement" handler:^(id data, WVJBResponseCallback responseCallback) {
        
    }];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [self load:self->fileUrl];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [self sendDeviceToken];
    [self pushMsg];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated){
        [[UIApplication sharedApplication]openURL:navigationAction.request.URL options:@{} completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if(navigationAction.sourceFrame.isMainFrame){
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}


#pragma mark - funs

- (void)clearCache{
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{}];
}

- (void)showAudio{
    [self.recorderView setHidden:false];
//    [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(self.view).offset(-150);
//    }];
    [UIView animateWithDuration:0.2 animations:^{
        CGRect rect = self.webView.frame;
        rect.origin.y = -250;
        self.webView.frame = rect;
//        [self.view layoutIfNeeded];
    }];
}

- (void)hiddenAudio{
    if(self.recorderView == nil) return;
    [self.recorderView setHidden:true];
//    [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(self.view).offset(0);
//    }];
    [UIView animateWithDuration:0.2 animations:^{
        CGRect rect = self.webView.frame;
        rect.size.height += 150;
        self.webView.frame = rect;
        [self.view layoutIfNeeded];
    }];
}

- (void)popAnimate{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *img = [Utils imageFromView:self.webView];
        if (self.popImgV == nil) {
            self.popImgV = [[UIImageView alloc]initWithFrame:self.view.frame];
            self.popImgV.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:self.popImgV];
        }
        self.popImgV.image = img;
        [self.popImgV setHidden:false];
        self.popImgV.frame = self.view.frame;
        self.popImgV.layer.shadowColor = [UIColor blackColor].CGColor;
        self.popImgV.layer.shadowOffset = CGSizeMake(0, 0);
        self.popImgV.layer.shadowOpacity = 0.5;
        self.popImgV.layer.shadowRadius = 5;
        [UIView animateWithDuration:0.2 animations:^{
            CGRect rect = self.popImgV.frame;
            rect.origin.x = self.view.frame.size.width;
            self.popImgV.frame = rect;
        } completion:^(BOOL finished) {
            if(finished) [self.popImgV setHidden:true];
        }];
        [self.view layoutIfNeeded];
    });
}

- (void)image:(UIImage*)img didFinishSavingWithError:(NSError*)error contextInfo:(id)info{
    if(error){
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        [self delay:1.0];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"已经保存到相册！"];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        [self delay:1.0];
    }
}

- (void)delay:(NSTimeInterval)time{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

- (void)callBack{
    [self.bridge callHandler:@"nativeBack"];
}

- (void)sendDeviceToken{
    NSString *dt = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
    if(dt && ![dt isEqualToString:@""]){
        [self.bridge callHandler:@"deviceToken" data:dt];
    }
}

- (void)pushMsg{
    NSString *userInfo = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserInfo"];
    if(userInfo && ![userInfo isEqualToString:@""]){
        [self.bridge callHandler:@"getPushMessage" data:userInfo];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"UserInfo"];
    }
}

- (void)readTime:(int)num{
    [self.bridge callHandler:@"scanTime" data:@(num)];
}

- (void)recordEndWithData:(NSDictionary *)dic{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *str = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self.bridge callHandler:@"recordEnd" data:str];
}

- (void)recordEndWithPath:(NSString *)path{
    NSData *da = [[NSData alloc]initWithContentsOfFile:path];
    NSString *baseString = [da base64EncodedStringWithOptions:0];
    NSLog(@"baseString:%@",baseString);
    [self.bridge callHandler:@"iosRecordEnd" data:baseString];
}

- (void)uploadEndPath:(NSString *)path{
    [self.webView reload];
}

#pragma mark - Location
- (void)initLocationService{
    CLLocationManager *manager = [[CLLocationManager alloc]init];
    [manager requestWhenInUseAuthorization];
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    manager.distanceFilter = kCLDistanceFilterNone;
    [manager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    self.location = locations.lastObject;
}

#pragma mark - Notification

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)name: kReachabilityChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
//    self.reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
//    [self.reach startNotifier];
}


- (void)reachabilityChanged: (NSNotification*)note{
    Reachability*curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status=[curReach currentReachabilityStatus];
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) {
            case ReachableViaWiFi:{
//                self->_networkStatusStyle = NetworkStatusStyleReachableViaWiFi;
                break;
            }
            case ReachableViaWWAN:{
//                self->_networkStatusStyle = NetworkStatusStyleReachableViaWWAN;
                break;
            }
            case NotReachable:{
//                self->_networkStatusStyle = NetworkStatusStyleNotReachable;
                break;
            }
            default:
                break;
        }
        [self.bridge callHandler:@"onNetworkChange"];
        
    });
}

- (void)keyboardWillShow:(NSNotification*)notif{
    [self.bridge callHandler:@"keyboard" data:@"YES" responseCallback:^(id responseData) {
        NSDictionary *kbInfo = notif.userInfo;
        CGRect kbRect = [[kbInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [self.bridge callHandler:@"keyboard" data:@(kbRect.size.height) responseCallback:^(id responseData) {}];
    }];
}

- (void)keyboardDidHide:(NSNotification*)notif{
    [self.bridge callHandler:@"keyboard" data:@"NO" responseCallback:^(id responseData) {}];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if(self.navigationController && gestureRecognizer == self.navigationController.interactivePopGestureRecognizer && ![self.navigationController.viewControllers.lastObject isKindOfClass:[DocumentViewController class]] && ![self.navigationController.viewControllers.lastObject isKindOfClass:[UploadViewController class]] && ![self.navigationController.viewControllers.lastObject isKindOfClass:[WebViewC class]]){
        [self callBack];
        return false;
    }
    return true;
}

@end
