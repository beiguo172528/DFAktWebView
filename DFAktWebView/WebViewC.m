//
//  WebViewC.m
//  Iat4
//
//  Created by DOFAR on 2021/11/15.
//  Copyright © 2021 DOFAR. All rights reserved.
//

#import "WebViewC.h"
#import <WebKit/WebKit.h>

@interface WebViewC ()<WKNavigationDelegate>
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSMutableArray *urls;
@end

@implementation WebViewC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.urls = [NSMutableArray array];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:nil action:nil];
//    self.automaticallyAdjustsScrollViewInsets = NO;
    [self createWebView];
    // Do any additional setup after loading the view.
    [self.urls addObject:_gotoUrl];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_gotoUrl]]];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"返回"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoBack)];
    UIBarButtonItem *escItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"关闭页面"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoEsc)];
    self.navigationItem.leftBarButtonItem = backItem;
    self.navigationItem.rightBarButtonItem = escItem;
}


- (void)gotoBack {
    if (_webView.canGoBack) {
        [_webView goBack];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)gotoEsc {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createWebView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.progressView = [[UIProgressView alloc]init];
    [self.view addSubview:self.progressView];
    self.progressView.frame = CGRectMake(0, 0, self.view.frame.size.width, 4);
    
    
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        config.mediaTypesRequiringUserActionForPlayback = NO;
    }
    self.webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) configuration:config ];
    [self.view addSubview:self.webView];
    self.webView.navigationDelegate = self;
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
//    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.view.mas_left);
//        make.right.equalTo(self.view.mas_right);
//        make.top.equalTo(self.progressView.mas_bottom);
//        make.bottom.equalTo(self.view.mas_bottom);
//    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqual:@"estimatedProgress"] && object == self.webView) {
        [self.progressView setAlpha:1.0f];
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        if (self.webView.estimatedProgress  >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:YES];
            }];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    self.title = webView.title;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
