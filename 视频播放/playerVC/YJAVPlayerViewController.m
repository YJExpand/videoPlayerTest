//
//  YJAVPlayerViewController.m
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "YJAVPlayerViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

static NSString * const PlayerItemStatusContext = @"PlayerItemStatusContext";
static NSString * const PlayerItemLoadedTimeRangesContext = @"PlayerItemLoadedTimeRangesContext";

/// 视频显示样式
typedef enum : NSUInteger {
    /// 普通竖屏
    videoShowStyleVertical_normal = 0,
    /// 左横屏
    videoShowStyleHorizontal_left = 1,
    /// 右横屏
    videoShowStyleHorizontal_right = 2,
} videoShowStyle;

/// 当前手势操作
typedef enum : NSUInteger {
    /// 默认无
    panGestureStyleNone = 0,
    /// 进度操作
    panGestureStyleProgress = 1,
    /// 屏幕亮度操作
    panGestureStyleBrightness = 2,
    /// 音量大小操作
    panGestureStyleVolume = 3,
} panGestureStyle;

@interface YJAVPlayerViewController ()

#pragma mark 视频

@property (weak, nonatomic) IBOutlet UIView *videoView;

@property (weak, nonatomic) IBOutlet UIView *videoBackgroundView;

@property (strong , nonatomic) AVPlayer *player;

@property (strong , nonatomic) AVPlayerItem *playerItem;

@property (strong , nonatomic) AVPlayerLayer *playerLayer;


#pragma mark 底部视图
/// 底部视图
@property (weak, nonatomic) IBOutlet UIView *bottomView;
/// 缓存进度
@property (weak, nonatomic) IBOutlet UIProgressView *cacheProgressView;
/// 播放进度
@property (weak, nonatomic) IBOutlet UISlider *playProgressView;
/// 总时间
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLB;
/// 播放时间
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLB;
/// 总状态
@property (weak, nonatomic) IBOutlet UISegmentedControl *operationBtns;

#pragma mark 系统操作（视频顶部视图）
/*
 ❗️注意 ： 测试亮度和音量大小需使用真机
 */
/// 系统操作view
@property (weak, nonatomic) IBOutlet UIView *systemOperationView;
/// 操作名称
@property (weak, nonatomic) IBOutlet UILabel *systemOperationNameLB;
/// 操作进度
@property (weak, nonatomic) IBOutlet UIProgressView *systemOperationProgressView;
/// 亮度
@property (assign , nonatomic) float brightnessProgress;
/// 音量
@property (assign , nonatomic) float volumeProgress;
/// 系统音量控件
@property (strong , nonatomic) UISlider* volumeViewSlider;

#pragma mark 切换视频操作视图
/// 切换视频
@property (weak, nonatomic) IBOutlet UIView *switchBackgroundView;

#pragma mark 速率视图
/// 速率
@property (weak, nonatomic) IBOutlet UIButton *rateBtn;
/// 速率选择View
@property (weak, nonatomic) IBOutlet UIView *rateSelectView;
/// 由小到大  [0.75、1.0、1.25、1.5、2.0]  默认1.0选中 , btn.tag = rateOptionBtnArr.index
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *rateOptionBtnArr;

#pragma mark 临时缓存
/// 开始平移point
@property (assign , nonatomic) CGPoint progress_panBeginPoint;
/// 视频显示样式
@property (assign , nonatomic) videoShowStyle style;
/// 当前手势操作
@property (assign , nonatomic) panGestureStyle currentPanStyle;

@end

@implementation YJAVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AVPlayer -> 使用";
    
    self.brightnessProgress = [UIScreen mainScreen].brightness;
    self.volumeProgress = [[AVAudioSession sharedInstance] outputVolume];
    
    // 设置音量控件
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.frame = CGRectZero;
    [self.view addSubview:volumeView];
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [self.volumeViewSlider setValue:self.volumeProgress animated:YES];
    [self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // 监听音量变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemVolumeDidChangeNoti:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    /// 初始化
    NSURL *localUrl = [YJManager getLocalVideoURL];
    self.playerItem = [[AVPlayerItem alloc] initWithURL:localUrl];
    
     // 在线链接
//     NSURL *webURL = [YJManager getWebVideoURL];
//     AVAsset *asset = [AVAsset assetWithURL:webURL];
//     self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
    
    /*
     可以监听self.playerItem.status 判断当前媒体的状态
     AVPlayerItemStatusUnknown  -> 不在播放队列
     AVPlayerItemStatusReadyToPlay  -> 可播放
     AVPlayerItemStatusFailed   -> 播放失败
     
     // 代码
     [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
     */
    /// 增加监听 ，注意要在dealloc移除，否则崩溃
    [self playerItemAddObserver];
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    
    /*
     AVPlayer要显示，就要结合AVPlayerLayer
     */
    self.playerLayer = [[AVPlayerLayer alloc] init];
    // 设置
    self.playerLayer.player = self.player;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.contentsScale = [UIScreen mainScreen].scale;
    // 添加到页面
    [self.videoBackgroundView.layer addSublayer:self.playerLayer];
    
    
    /*
     AVPlayer提供一个block，当播放进度改变时，则会自动调取block,
     @param interval 在正常回放期间，根据播放机当前时间的进度，调用块的间隔。
     */
    __weak __typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
       
        /// 当前播放时间
        NSTimeInterval  current = CMTimeGetSeconds(time);
        /// 总时间
        NSTimeInterval  total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        /// 当前进度
        float progress = current / total;
        [weakSelf.playProgressView setValue:progress animated:YES];
        
        weakSelf.totalTimeLB.text = [weakSelf formatWithTime:total];
        weakSelf.currentTimeLB.text = [weakSelf formatWithTime:current];
        
    }];
    
    /// 监听视频是否播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayEndNoti:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    // 添加手势
    UIPanGestureRecognizer *moveTag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanWithGesture:)];
    self.videoView.userInteractionEnabled = YES;
    [self.videoView addGestureRecognizer:moveTag];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)dealloc
{
    NSLog(@"销毁 %s",__func__);
    
    /// 移除监听
    [self playerItemRemoveObserver];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.playerLayer.frame = self.videoView.bounds;
}


#pragma mark - action

- (IBAction)operationClick:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
        case 0: // 播放
            [self.player play];
            break;
        case 1: // 暂停
            [self.player pause];
            break;
        case 2: // 停止
            self.player.rate = 0.0;
            break;
        default:
            break;
    }
    
}

- (IBAction)videoGravityClick:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0: // AVLayerVideoGravityResizeAspect ： 默认原画（不拉伸，不平铺）
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case 1: // AVLayerVideoGravityResizeAspectFill ： 不拉伸，平铺
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case 2: // AVLayerVideoGravityResize ： 拉伸平铺
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            break;
    }
    
}

- (IBAction)sliderBeginClick:(UISlider *)sender {
    
    // 当可以播放视频时才能操作进度条
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
       
        if (self.operationBtns.selectedSegmentIndex == 0) { // 播放状态
             [self.player pause];
        }
    }
}

- (IBAction)sliderEndClick:(UISlider *)sender {
    // 当可以播放视频时才能操作进度条
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        /// 当前定位
        float progress = sender.value;
        NSTimeInterval currentTime = CMTimeGetSeconds(self.playerItem.duration) * progress;
        [self playVideoWithTime:currentTime];
        
    }
    
}

/// 处理旋转
- (IBAction)rotateBtnClick:(UIButton *)sender {
    /*
     CGAffineTransform CGAffineTransformMake (CGFloat a,CGFloat b,CGFloat c,CGFloat d,CGFloat tx,CGFloat ty);
     其中tx用来控制在x轴方向上的平移
     ty用来控制在y轴方向上的平移
     a用来控制在x轴方向上的缩放
     d用来控制在y轴方向上的缩放
     abcd共同控制旋转
     */
    
    // 正常竖屏
    CATransform3D normal = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(0));
    // 倒竖屏
    CATransform3D inverted = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI));
    // 右横屏
    CATransform3D right = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(-M_PI_2));
    // 左横屏
    CATransform3D left = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2));
    
    switch (self.style) {
        case videoShowStyleVertical_normal:
            self.playerLayer.transform = left;
            self.style = videoShowStyleHorizontal_left;
            break;
        case videoShowStyleHorizontal_left:
            self.playerLayer.transform = right;
            self.style = videoShowStyleHorizontal_right;
            break;
        case videoShowStyleHorizontal_right:
            self.playerLayer.transform = normal;
            self.style = videoShowStyleVertical_normal;
            break;
        default:
            break;
    }
    
    self.playerLayer.frame = self.videoView.bounds;
}

- (IBAction)videoSwitchBtnClick:(UIButton *)sender {
    
    self.switchBackgroundView.hidden = true;
    
    switch (sender.tag) {
        case 1:  // 重播
            [self playVideoWithTime:0];
            break;
        case 2:     // 下一个
            // 1、先移除监听，避免崩溃
            [self playerItemRemoveObserver];
            // 2、重写playerItem
            self.playerItem = [AVPlayerItem playerItemWithURL:[YJManager getLocalVideoURL]];
            // 3、替换
            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            // 4、添加监听
            [self playerItemAddObserver];
            // 5、播放
            [self.player play];
            self.operationBtns.selectedSegmentIndex = 0;
            break;
        default:
            break;
    }
}

/// 速率弹窗
- (IBAction)rateBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    self.rateSelectView.hidden = !sender.isSelected;
}

/// 选中速率
- (IBAction)rateOptionBtnClick:(UIButton *)sender {
    // 不可播放时
    if (self.playerItem.status != AVPlayerItemStatusReadyToPlay) return;
    
    NSString *rateStr = [sender.titleLabel.text stringByReplacingOccurrencesOfString:@"x" withString:@""];
    
    float rate = [rateStr floatValue];
    // 修改速率
    self.player.rate = rate;
    if (self.operationBtns.selectedSegmentIndex != 0) {   // 不可播放状态
        [self.player pause];
    }
    
    if (rate != 1) {
        [self.rateBtn setTitle:sender.titleLabel.text forState:UIControlStateNormal];
    }else{
        [self.rateBtn setTitle:@"速率" forState:UIControlStateNormal];
    }
    
    for (UIButton *btn in self.rateOptionBtnArr) {
        btn.selected = NO;
    }
    
    sender.selected = YES;
    
    self.rateSelectView.hidden = YES;
    self.rateBtn.selected = NO;
    
}



/// 手势滑动
- (void)movePanWithGesture:(UIPanGestureRecognizer *)tag{
    // 不可拖动
    if (self.playerItem.status != AVPlayerItemStatusReadyToPlay) return;
    
    /*
     translationInView:方法获取View的偏移量；
     setTranslation:方法设置手势的偏移量；
     velocityInView:方法获取速度；
     */
    
    // 获取view的偏移量
    CGPoint point = [tag translationInView:self.videoView];
    
    if (tag.state == UIGestureRecognizerStateBegan) {  // 开始拖动
        
        NSLog(@"Began : point.x -> %f , point.y -> %f",point.x,point.y);
        self.progress_panBeginPoint = point;
        
    } else if (tag.state == UIGestureRecognizerStateEnded) { // 停止拖动
        NSLog(@"Ended : point.x -> %f , point.y -> %f",point.x,point.y);
        
        switch (self.currentPanStyle) {
            case panGestureStyleProgress:{
                /// 当前定位,开始播放
                float progress = self.playProgressView.value;
                NSTimeInterval currentTime = CMTimeGetSeconds(self.playerItem.duration) * progress;
                [self playVideoWithTime:currentTime];
                break;
                
            }
            case panGestureStyleBrightness:
            case panGestureStyleVolume:{
                // 一秒后隐藏
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.systemOperationView.hidden = true;
                });
                break;
                
            }
            default:
                break;
        }
        
        // 格式化
        self.currentPanStyle = panGestureStyleNone;
        
    }else if (tag.state == UIGestureRecognizerStateChanged) { // 拖动中
        NSLog(@"Changed : point.x -> %f , point.y -> %f",point.x,point.y);
        
        if (self.currentPanStyle == panGestureStyleNone) {  // 未区分手势滑动的样式
            
            float moveX = fabs(point.x - self.progress_panBeginPoint.x);
            float moveY = fabs(point.y - self.progress_panBeginPoint.y);
            
            CGPoint currentPoint = [tag locationInView:self.videoBackgroundView];
            if (moveX >= moveY) {  // 属于进度操作
                self.currentPanStyle = panGestureStyleProgress;
                
                if (self.operationBtns.selectedSegmentIndex == 0) {   // 正在播放，暂停播放
                    [self.player pause];
                }
                
            }else if (currentPoint.x <= self.videoView.frame.size.width / 2){  // 亮度操作
                self.currentPanStyle = panGestureStyleBrightness;
            }else{// 音量操作
                self.currentPanStyle = panGestureStyleVolume;
            }
            
        }
        
        
        switch (self.currentPanStyle) {
            case panGestureStyleProgress:{   // 进度
                
                float move = point.x - self.progress_panBeginPoint.x;
                float progress = (move / self.videoView.frame.size.width);
                
                float playProgressValue = self.playProgressView.value;
                float progressEnd = playProgressValue + progress;
                if (progressEnd > 1) {  // 直接加载完
                    [self.playProgressView setValue:1 animated:YES];
                } else if (progressEnd < 0){ // 重新加载
                    [self.playProgressView setValue:0 animated:YES];
                }else{
                    [self.playProgressView setValue:progressEnd animated:YES];
                }
                
                break;
            }
            case panGestureStyleVolume:{     // 音量
                
                self.systemOperationView.hidden = false;
                float move = self.progress_panBeginPoint.y - point.y;
                self.volumeProgress = (move / self.videoView.frame.size.height) * 4 + self.volumeProgress;  // *4 -> 更容易改变音量，不需要滑动更多
                self.systemOperationNameLB.text = @"音量";
                
                if (self.volumeProgress > 1) {  // 已经是最大了
                    self.volumeProgress = 1;
                } else if (self.volumeProgress < 0){ // 已经是最小了
                    self.volumeProgress = 0;
                }
                [self.systemOperationProgressView setProgress:self.volumeProgress];
                // 调节音量
                [self.volumeViewSlider setValue:self.volumeProgress];
                
                break;
            }
            case panGestureStyleBrightness:{     // 亮度
                
                self.systemOperationView.hidden = false;
                float move = self.progress_panBeginPoint.y - point.y;
                self.brightnessProgress = (move / self.videoView.frame.size.height) * 4 + self.brightnessProgress;  // *4 -> 更容易改变亮度，不需要滑动更多
                self.systemOperationNameLB.text = @"亮度";
                if (self.brightnessProgress > 1) {  // 已经是最大了
                    self.brightnessProgress = 1;
                } else if (self.brightnessProgress < 0){ // 已经是最小了
                    self.brightnessProgress = 0;
                }
                [self.systemOperationProgressView setProgress:self.brightnessProgress];
                // 调节亮度
                [[UIScreen mainScreen] setBrightness:self.brightnessProgress];
                
                break;
            }
            default:
                break;
        }
        
        
        
        self.progress_panBeginPoint = point;
    }
}

//监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    AVPlayerItem *item = (AVPlayerItem *)object;
    
    if (context == (__bridge void *)(PlayerItemStatusContext)) {
        
        NSLog(@"item.status  -> %zd",item.status);
        
        /// 当前播放时间
        NSTimeInterval  current = CMTimeGetSeconds(item.currentTime);
        /// 总时间
        NSTimeInterval  total = CMTimeGetSeconds(item.duration);
        
        self.totalTimeLB.text = [self formatWithTime:total];
        self.currentTimeLB.text = [self formatWithTime:current];
    }
    
    
    if (context == (__bridge void *)PlayerItemLoadedTimeRangesContext) {
       [self.cacheProgressView setProgress:[self availableDurationWithplayerItem:item]];
    }
}

/// 音量变化
- (void)systemVolumeDidChangeNoti:(NSNotification *)noti{
    float voiceSize = [[noti.userInfo valueForKey:@"AVSystemController_AudioVolumeNotificationParameter"]floatValue];
    self.volumeProgress = voiceSize;
}

/// 视频播放完毕
- (void)videoPlayEndNoti:(NSNotification *)noti{
    self.switchBackgroundView.hidden = false;
}

#pragma mark - Other
/// 获取当前缓存进度
- (NSTimeInterval)availableDurationWithplayerItem:(AVPlayerItem *)playerItem{
    
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;   // 计算缓存总进度
    
    return result;
}


/// 格式化时间
- (NSString *)formatWithTime:(NSTimeInterval)duration{
    int minute = 0, hour = 0, secend = duration;
    minute = (secend % 3600)/60;
    hour = secend / 3600;
    secend = secend % 60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, secend];
}


/// 定点播放视频
- (void)playVideoWithTime:(NSTimeInterval)currentTime{
    
    CMTime time = CMTimeMake(currentTime, 1);
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        
    }];
    
    if (self.operationBtns.selectedSegmentIndex == 0) {   // 播放状态
        [self.player play];
    }
}

/// playItem增加监听
- (void)playerItemAddObserver{
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:0
                         context:(__bridge void *)(PlayerItemStatusContext)];
    
    // 监听当前视频的缓存程度
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:0
                         context:(__bridge void *)PlayerItemLoadedTimeRangesContext];
}


/// playerItem 移除监听
- (void)playerItemRemoveObserver{
    [self.playerItem removeObserver:self
                         forKeyPath:@"status"
                            context:(__bridge void *)(PlayerItemStatusContext)];
    
    [self.playerItem removeObserver:self
                         forKeyPath:@"loadedTimeRanges"
                            context:(__bridge void *)(PlayerItemLoadedTimeRangesContext)];
}
@end
