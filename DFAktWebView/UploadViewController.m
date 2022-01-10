//
//  UploadViewController.m
//  Iat4
//
//  Created by DOFAR on 2020/8/12.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import "SVProgressHUD.h"
#import "UploadViewController.h"
#import "AFNetworking/AFURLSessionManager.h"

@interface UploadViewController ()<UIDocumentPickerDelegate>
@property (strong, nonatomic) UIImageView *iconImgV;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UILabel *progressLabel;
@property (strong, nonatomic) UILabel *tipStr;
@end

@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self changeUI];
    [self downLoadFile];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)changeUI{
    self.view.backgroundColor = [UIColor whiteColor];
    self.iconImgV = [[UIImageView alloc]initWithFrame:CGRectZero];
    self.iconImgV.image = [UIImage imageNamed:@"icon"];
    [self.view addSubview:self.iconImgV];
    self.iconImgV.frame = CGRectMake((self.view.frame.size.width - 80)/2, 150, 80, 80);
    
    self.tipStr = [[UILabel alloc]initWithFrame:CGRectZero];
    self.tipStr.textColor = [UIColor colorWithRed:(float)51/225 green:(float)51/225 blue:(float)51/225 alpha:1];
    self.tipStr.font = [UIFont systemFontOfSize:17];
    self.tipStr.text = @"数据更新中，请耐心等候";
    self.tipStr.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipStr];
    self.tipStr.frame = CGRectMake(0, self.iconImgV.frame.origin.y + 80 + 18, self.view.frame.size.width, 21);
    
    self.progressView = [[UIProgressView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:self.progressView];
    self.progressView.frame = CGRectMake(15, (self.view.frame.size.height - 4)/2, self.view.frame.size.width - 30, 4);
    
    
    self.progressLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    self.progressLabel.textColor = [UIColor colorWithRed:(float)153/225 green:(float)153/225 blue:(float)153/225 alpha:1];
    self.progressLabel.font = [UIFont systemFontOfSize:13];
    self.progressLabel.text = @"0%";
    self.progressLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.progressLabel];
    self.progressLabel.frame = CGRectMake(50, (self.progressView.frame.origin.y + 14), self.view.frame.size.width - 65, 16);
    
    self.iconImgV.layer.masksToBounds = YES;
    self.iconImgV.layer.cornerRadius = 10;
    if(!self.isUp){
        self.tipStr.text = @"数据下载中，请耐心等候";
    }
}

- (void)downLoadFile{
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURL *url = [NSURL URLWithString:self.updateStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSArray *arr1 = [self.updateStr componentsSeparatedByString:@"?"];
    path = [path stringByAppendingPathComponent:[arr1.firstObject componentsSeparatedByString:@"/"].lastObject];
    if([[NSFileManager defaultManager]fileExistsAtPath:path]){
        NSError *err;
        [[NSFileManager defaultManager]removeItemAtPath:path error:&err];
        if(err){
            NSLog(@"删除文件失败");
        }
    }
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = downloadProgress.fractionCompleted;
            self.progressLabel.text = [NSString stringWithFormat:@"%d%%",(int)round(downloadProgress.fractionCompleted * 100)];
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /* 设定下载到的位置 */
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//        self.localFileUrl = filePath;
        if(self.isUp){
//            NSString *url = [Utils uSSZipArchiveWithFilePath:filePath.path withCover:true];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                if(self.delegate && [self.delegate respondsToSelector:@selector(uploadEndPath:)]){
//                    [self.delegate uploadEndPath:url];
//                }
//                [self.navigationController popViewControllerAnimated:true];
//            });
        }
        else{
            [self saveFile:filePath.path];
        }
    }];
    [downloadTask resume];
}

- (void)saveFile:(NSString *)fileUrl{
    NSString *path = [self.updateStr componentsSeparatedByString:@"?"][0];
    NSString *type = [[path componentsSeparatedByString:@"."].lastObject lowercaseString];
    if ([type isEqualToString:@"jpg"] || [type isEqualToString:@"png"] || [type isEqualToString:@"jpeg"]) {
        UIImage *image = [UIImage imageWithContentsOfFile:fileUrl];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(savedPhotosAlbum:withDidFinishSavingWithError:withContextInfo:), nil);
    }
    else if( [type isEqualToString:@"mp4"]|| [type isEqualToString:@"mpg"]|| [type isEqualToString:@"mpeg"]|| [type isEqualToString:@"wmv"]|| [type isEqualToString:@"amv"]|| [type isEqualToString:@"avi"]|| [type isEqualToString:@"rmvb"]|| [type isEqualToString:@"mtv"]|| [type isEqualToString:@"flv"]){
        NSURL *url = [NSURL URLWithString:fileUrl];
        BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([url path]);
        if (compatible){
            UISaveVideoAtPathToSavedPhotosAlbum([url path], self, @selector(savedPhotosAlbum:withDidFinishSavingWithError:withContextInfo:), nil);
        }
    }
    else{
        UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithURL:[NSURL fileURLWithPath:fileUrl] inMode:UIDocumentPickerModeMoveToService];
        documentPickerVC.delegate = self;
        documentPickerVC.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:documentPickerVC animated:YES completion:nil];
    }
}

- (void)savedPhotosAlbum:(UIImage*)image withDidFinishSavingWithError:(NSError*)error withContextInfo:(id)contextInfo{
    if (error) {
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
    }else {
        [SVProgressHUD showSuccessWithStatus:@"已经保存到相册！"];
    }
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [self delay:1.0];
}

- (void)delay:(NSTimeInterval)time{
    dispatch_time_t delayInSeconds = dispatch_time(DISPATCH_TIME_NOW,(int64_t)(time * NSEC_PER_SEC));
    dispatch_after(delayInSeconds, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismissWithDelay:time];
        [self.navigationController popViewControllerAnimated:true];
    });
}


- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    // 获取授权
    BOOL fileUrlAuthozied = [urls.firstObject startAccessingSecurityScopedResource];
    if (fileUrlAuthozied) {
        // 通过文件协调工具来得到新的文件地址，以此得到文件保护功能
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        
        [fileCoordinator coordinateReadingItemAtURL:urls.firstObject options:0 error:&error byAccessor:^(NSURL *newURL) {
            [self.navigationController popViewControllerAnimated:true];
        }];
        [urls.firstObject stopAccessingSecurityScopedResource];
    } else {
        // 授权失败
        NSLog(@"授权失败");
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller{
    [self.navigationController popViewControllerAnimated:true];
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
