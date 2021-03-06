//
//  MOKOSecretTrainRecorder.m
//  MOKORecord
//
//  Created by Spring on 2017/4/26.
//  Copyright © 2017年 Spring. All rights reserved.
//
#import "Utils.h"
#import "MOKORecorderTool.h"

#define MOKOSecretTrainRecordFielName @"lvRecord.wav"

@interface MOKORecorderTool()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioSession *session;

@end

@implementation MOKORecorderTool

static MOKORecorderTool *instance = nil;
#pragma mark - 单例
+ (instancetype)sharedRecorder
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    });
    return instance;
}

- (void)startRecording
{
    // 录音时停止播放 删除曾经生成的文件
    [self stopPlaying];
    [self destructionRecordingFile];
    // 真机环境下需要的代码
    self.session = [AVAudioSession sharedInstance];
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.recorder record];
}

- (void)updateImage
{
    [self.recorder updateMeters];
    
    double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    float result  = 10 * (float)lowPassResults;
    //NSLog(@"%f", result);
    int no = 0;
    if (result > 0 && result <= 1.3) {
        no = 1;
    } else if (result > 1.3 && result <= 2) {
        no = 2;
    } else if (result > 2 && result <= 3.0) {
        no = 3;
    } else if (result > 3.0 && result <= 3.0) {
        no = 4;
    } else if (result > 5.0 && result <= 10) {
        no = 5;
    } else if (result > 10 && result <= 40) {
        no = 6;
    } else if (result > 40) {
        no = 7;
    }
    if ([self.delegate respondsToSelector:@selector(recorder:didstartRecoring:)])
    {
        [self.delegate recorder:self didstartRecoring: no];
    }
    else
    {
        
    }
}
- (void)stopRecording
{
    if ([self.recorder isRecording])
    {
        [self.recorder stop];
    }
}
- (void)playRecordingFileWithPath:(NSString*)path
{
    [self.recorder stop];// 播放时停止录音
    // 正在播放就返回
    if ([self.player isPlaying])
    {
        return;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
    NSError * error;
    if (path == nil || [path isEqualToString:@""]) {
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileUrl error:&error];
    }
    else {
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    }
    self.player.delegate = self;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
//    [self.player play];
}

- (void)stopPlaying
{
    [self.player stop];
}

#pragma mark - 懒加载
- (AVAudioRecorder *)recorder {
    if (!_recorder) {
        // 1.获取沙盒地址
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filePath = [path stringByAppendingPathComponent:MOKOSecretTrainRecordFielName];
        self.recordFileUrl = [NSURL fileURLWithPath:filePath];
        
        // 3.设置录音的一些参数
//        NSMutableDictionary *setting = [NSMutableDictionary dictionary];
        // 音频格式
//        setting[AVFormatIDKey] = @(kAudioFormatMPEG4AAC);
        // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
//        [setting setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];//ID
//        [setting setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];//解码率
//        setting[AVSampleRateKey] = @(16000.0);
//        // 音频通道数 1 或 2
//        setting[AVNumberOfChannelsKey] = @(1);
//        // 线性音频的位深度  8、16、24、32
//        setting[AVLinearPCMBitDepthKey] = @(16);
//        //录音的质量
//        setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];

        NSDictionary *setting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                                 [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                 [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                 [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                 [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                 [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,nil];
        
        NSError* error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:setting error:&error];
        if (error) {
            NSLog(@"创建失败，原因是 = %@", error);
        }
        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;
        [_recorder prepareToRecord];
    }
    return _recorder;
}

- (void)destructionRecordingFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.recordFileUrl)
    {
        [fileManager removeItemAtURL:self.recordFileUrl error:NULL];
    }
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    //录音结束
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //录音播放结束
    if ([self.delegate respondsToSelector:@selector(recordToolDidFinishPlay:)])
    {
        [self.delegate recordToolDidFinishPlay:self];
    }
}

@end
