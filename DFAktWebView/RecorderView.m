//
//  RecorderView.m
//  Iat4
//
//  Created by DOFAR on 2020/7/13.
//  Copyright © 2020 DOFAR. All rights reserved.
//

#import "Utils.h"
#import "RecorderView.h"
#import "MOKORecorderTool.h"
#import "MOKORecordShowManager.h"
#import "MOKORecordButton.h"
#import "DFPopupController.h"
#import "SVProgressHUD.h"
#import "AFNetworking/AFHTTPSessionManager.h"

#define kFakeTimerDuration       1
#define kMaxRecordDuration       60     //最长录音时长
#define kRemainCountingDuration  10     //剩余多少秒开始倒计时

@interface RecorderView()<MOKOSecretTrainRecorderDelegate>
@property (nonatomic, strong) MOKORecordShowManager *voiceRecordCtrl;
@property (nonatomic, assign) MOKORecordState currentRecordState;
@property (nonatomic, strong) NSTimer *fakeTimer;
@property (nonatomic, assign) float duration;
@property (nonatomic, assign) BOOL canceled;
@property (strong, nonatomic) MOKORecordButton *recordButton;
@property (nonatomic, strong) MOKORecorderTool *recorder;
@end

@implementation RecorderView

- (void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor whiteColor];
    NSLog(@"awakeFromNib");
    [self createRecordButton];
}

- (instancetype)init{
    self = [super init];
    self.backgroundColor = [UIColor whiteColor];
    NSLog(@"init");
    [self createRecordButton];
    return self;
}

- (void)didReceiveMemoryWarning{
    NSLog(@"内存消耗过大 问题");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)createRecordButton {
    self.recordButton = [MOKORecordButton buttonWithType:UIButtonTypeCustom];
    self.recorder = [MOKORecorderTool sharedRecorder];
    self.recorder.delegate = self;
    [self.recordButton setHidden:false];
//    self.recordButton.backgroundColor = [UIColor redColor];
//    self.recordButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.recordButton setImage:[UIImage imageNamed:@"录音默认"] forState:UIControlStateNormal];
//    [self.recordButton setTitle:NSLocalizedString(@"Hold", @"") forState:UIControlStateNormal];
//    [self.recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self addSubview:self.recordButton];
    self.recordButton.frame = CGRectMake((self.bounds.size.width - 100)/2 , (self.bounds.size.height - 100)/2, 100, 100);
    self.recordButton.clipsToBounds = YES;
    self.recordButton.layer.cornerRadius = 50;
    //录音相关
    [self toDoRecord];
}

- (void)touch{
    [self.recordButton recordTouchUpInsideAction];
}

-(void)toDoRecord{
    __weak typeof(self) weak_self = self;
    //手指按下
    self.recordButton.recordTouchDownAction = ^(MOKORecordButton *sender){
        //如果用户没有开启麦克风权限,不能让其录音
//        if (weak_self.mediaPlayer) {
//            [weak_self.mediaPlayer pause];
//        }
        if (![weak_self canRecord]) return;
        if (sender.highlighted) {
            sender.highlighted = YES;
            [sender setButtonStateWithRecording];
        }
        [weak_self.recorder startRecording];
        weak_self.currentRecordState = MOKORecordState_Recording;
        [weak_self dispatchVoiceState];
    };
    
    //手指抬起
    self.recordButton.recordTouchUpInsideAction = ^(MOKORecordButton *sender){
//        if (weak_self.mediaPlayer) {
//            [weak_self.mediaPlayer play];
//        }
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filePath = [path stringByAppendingPathComponent:@"lvRecord.wav"];
        if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
            [weak_self.recorder playRecordingFileWithPath:nil];
            [weak_self uploadFileUrl:filePath];
//            [weak_self sendAudioWithPath:filePath];
        }
        [sender setButtonStateWithNormal];
        [weak_self.recorder stopRecording];
        weak_self.currentRecordState = MOKORecordState_Normal;
        [weak_self dispatchVoiceState];
    };
    
    //手指滑出按钮
    self.recordButton.recordTouchUpOutsideAction = ^(MOKORecordButton *sender){
//        if (weak_self.mediaPlayer) {
//            [weak_self.mediaPlayer play];
//        }
        [sender setButtonStateWithNormal];
        weak_self.currentRecordState = MOKORecordState_Normal;
        [weak_self dispatchVoiceState];
    };
    
    //中间状态  从 TouchDragInside ---> TouchDragOutside
    self.recordButton.recordTouchDragExitAction = ^(MOKORecordButton *sender){
        weak_self.currentRecordState = MOKORecordState_ReleaseToCancel;
        [weak_self dispatchVoiceState];
    };
    
    //中间状态  从 TouchDragOutside ---> TouchDragInside
    self.recordButton.recordTouchDragEnterAction = ^(MOKORecordButton *sender){
        weak_self.currentRecordState = MOKORecordState_Recording;
        [weak_self dispatchVoiceState];
    };
}

//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord {
    __block BOOL bCanRecord = YES;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                bCanRecord = YES;
            }
            else {
                bCanRecord = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DFPopupController popupViewAddToViewController:[Utils getControllerFromView:self] style:DFPopupControllerStyleDefaule Message:@"app需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"];
                });
            }
        }];
    }
    return bCanRecord;
}

- (void)resetState {
    [self stopFakeTimer];
    self.duration = 0;
    self.canceled = YES;
}

- (void)dispatchVoiceState {
    if (_currentRecordState == MOKORecordState_Recording) {
        self.canceled = NO;
        [self startFakeTimer];
    }
    else if (_currentRecordState == MOKORecordState_Normal) {
        [self resetState];
    }
    [self.voiceRecordCtrl updateUIWithRecordState:_currentRecordState];
}

- (MOKORecordShowManager *)voiceRecordCtrl {
    if (_voiceRecordCtrl == nil) {
        _voiceRecordCtrl = [MOKORecordShowManager new];
    }
    return _voiceRecordCtrl;
}

- (void)startFakeTimer {
    if (_fakeTimer) {
        [_fakeTimer invalidate];
        _fakeTimer = nil;
    }
    self.fakeTimer = [NSTimer scheduledTimerWithTimeInterval:kFakeTimerDuration target:self selector:@selector(onFakeTimerTimeOut) userInfo:nil repeats:YES];
    [_fakeTimer fire];
}

- (void)stopFakeTimer {
    if (_fakeTimer) {
        [_fakeTimer invalidate];
        _fakeTimer = nil;
    }
}

- (void)onFakeTimerTimeOut {
    self.duration += kFakeTimerDuration;
    float remainTime = kMaxRecordDuration - self.duration;
    if ((int)remainTime == 0) {
        self.currentRecordState = MOKORecordState_Normal;
        [self dispatchVoiceState];
    }
    else if ([self shouldShowCounting]) {
        self.currentRecordState = MOKORecordState_RecordCounting;
        [self dispatchVoiceState];
        [self.voiceRecordCtrl showRecordCounting:remainTime];
    }
    else {
        [self.recorder.recorder updateMeters];
        float   level = 0.0f;                // The linear 0.0 .. 1.0 value we need.
        
        float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
        float decibels = [self.recorder.recorder peakPowerForChannel:0];
        if (decibels < minDecibels) {
            level = 0.0f;
        }
        else if (decibels >= 0.0f) {
            level = 1.0f;
        }
        else {
            float   root            = 2.0f;
            float   minAmp          = powf(10.0f, 0.05f * minDecibels);
            float   inverseAmpRange = 1.0f / (1.0f - minAmp);
            float   amp             = powf(10.0f, 0.05f * decibels);
            float   adjAmp          = (amp - minAmp) * inverseAmpRange;
            level = powf(adjAmp, 1.0f / root);
        }
        
        [self.voiceRecordCtrl updatePower:level];
    }
}
- (BOOL)shouldShowCounting {
    if (self.duration >= (kMaxRecordDuration - kRemainCountingDuration) && self.duration < kMaxRecordDuration && self.currentRecordState != MOKORecordState_ReleaseToCancel) {
        return YES;
    }
    return NO;
}

- (void)uploadFileUrl:(NSString*)filePath{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    if (audioDurationSeconds < 1) {
        [SVProgressHUD showErrorWithStatus:@"录音时间太短"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    NSString *url = [[NSUserDefaults standardUserDefaults]objectForKey:@"URL"];
    NSString *Token = [[NSUserDefaults standardUserDefaults]objectForKey:@"Token"];
    if(!url || [url isEqualToString:@""] || !Token || [Token isEqualToString:@""]){
        if(self.delegate && [self.delegate respondsToSelector:@selector(recordEndWithPath:)]){
            [self.delegate recordEndWithPath:filePath];
        }
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/jpeg", nil];
    [manager.requestSerializer setValue:Token forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    [manager POST:url parameters:para headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"file" fileName:@"lvRecord.wav$1" mimeType:@"application/octet-stream" error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        BOOL haveData = false;
        if(responseObject){
            NSDictionary *dic = responseObject;
            if([dic[@"code"]  isEqual: @(200)] && dic[@"data"] && dic[@"data"][0]){
                if(self.delegate && [self.delegate respondsToSelector:@selector(recordEndWithData:)]){
                    haveData = true;
                    [self.delegate recordEndWithData:dic[@"data"][0]];
                }
            }else{
                [SVProgressHUD showErrorWithStatus:@"上传录音失败"];
                [SVProgressHUD dismissWithDelay:1];
            }
        }
        if(!haveData){
            [self.delegate recordEndWithData:@{}];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:@"上传录音失败"];
        [SVProgressHUD dismissWithDelay:1];
    }];
}

@end
