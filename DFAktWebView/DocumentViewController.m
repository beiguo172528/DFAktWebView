//
//  DocumentViewController.m
//  Iat4
//
//  Created by DOFAR on 2020/6/16.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import "DocumentViewController.h"
#import "Utils.h"
#import <QuickLook/QuickLook.h>
#import "SVProgressHUD.h"
#import "AFURLSessionManager.h"

@interface DocumentViewController ()<UIDocumentInteractionControllerDelegate,QLPreviewControllerDataSource,QLPreviewControllerDelegate>
@property(nonatomic, copy) NSString* filePath;
@property(nonatomic, strong) NSURL* localFileUrl;
@property (nonatomic,strong) QLPreviewController *previewController;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) int timeNum;
@end

@implementation DocumentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"文件预览";//文件预览
    self.view.backgroundColor = [UIColor whiteColor];
    [self createpreviewController];
    [self downLoadFile];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:false];
    self.timeNum = 0;
    if(!self.timer){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            self.timeNum += 1;
        }];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(self.timer){
        if(self.delegate && [self.delegate respondsToSelector:@selector(readTime:)]){
            [self.delegate readTime:self.timeNum];
        }
        self.timeNum = 0;
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)createOtherAppOpen{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"其他应用打开"] style:UIBarButtonItemStylePlain target:self action:@selector(openUseOtherApp)];
}

- (void)openUseOtherApp{
    if (!_documentInteractionController) {
        _documentInteractionController = [UIDocumentInteractionController
                                          interactionControllerWithURL:self.localFileUrl];
        [_documentInteractionController setDelegate:self];
    }
    [_documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
}

- (void)downLoadFile{
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURL *url = [NSURL URLWithString:self.fileUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSString *imageDir = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), @"IMGS"];
    BOOL isDir = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:imageDir isDirectory:&isDir];
    if(!(isDir && existed)){
        [[NSFileManager defaultManager]createDirectoryAtPath:imageDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSArray *arr1 = [self.fileUrl componentsSeparatedByString:@"?"];
    imageDir = [imageDir stringByAppendingPathComponent:[arr1.firstObject componentsSeparatedByString:@"/"].lastObject];
    if(![Utils getIsIpad]){
        [SVProgressHUD showProgress:0 status:@"Loading"];
    }
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        [SVProgressHUD showProgress:downloadProgress.fractionCompleted status:@"Loading"];
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /* 设定下载到的位置 */
        return [NSURL fileURLWithPath:imageDir];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        self.localFileUrl = filePath;
        [SVProgressHUD dismiss];
        if(self.isCanOtherOpen){
            [self createOtherAppOpen];
        }
        [self loadPreviewController];
    }];
    [downloadTask resume];
}

- (void)createpreviewController{
    _previewController = [[QLPreviewController alloc] init];
    _previewController.dataSource = self;
    _previewController.delegate = self;
    _previewController.view.backgroundColor = UIColor.whiteColor;
    _previewController.view.frame = CGRectZero;
}

- (void)loadPreviewController{
    [self addChildViewController:self->_previewController];
    [_previewController didMoveToParentViewController:self];
    _previewController.currentPreviewItemIndex = 0;
    [self.view addSubview:_previewController.view];
    _previewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
//    if (@available(iOS 12.0, *)) {
//        [_previewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(self.view.mas_left);
//            make.right.equalTo(self.view.mas_right);
//            make.bottom.equalTo(self.view.mas_bottom);
//            make.top.equalTo(self.view.mas_top).offset(VIEWSAFEAREAINSETS(self.view).top);
//        }];
//    }
//    else {
//
//        [_previewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(self.view.mas_left);
//            make.right.equalTo(self.view.mas_right);
//            make.bottom.equalTo(self.view.mas_bottom);
//            make.top.equalTo(self.view.mas_top).offset(64);
//        }];
//    }
    [_previewController reloadData];
}

#pragma MARK - previewController delegate
- (id)previewController: (QLPreviewController *) controller previewItemAtIndex: (NSInteger) index{
    return self.localFileUrl;
}
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)controller{
    return self;
}
 
//为快速预览指定View
- (UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller{
    return self.view;
}
 
//为快速预览指定显示范围
- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller{
    return CGRectMake(0, 0, self.view.frame.size.width, 300);
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
