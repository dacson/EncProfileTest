//
//  ViewController.m
//  x264_enc
//
//  Created by zhangjunhai on 16/6/14.
//  Copyright © 2016年 yy company. All rights reserved.
//

#import "ViewController.h"

static struct timeval timeStart;
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *VnameLabel;
@property (nonatomic) int  filesize;
@property (nonatomic) x265_func* x265func;
@property (nonatomic) x264_func* x264func;

- (void) Paraminit;
- (void) videoencodefunc;
- (unsigned char*) videoread;

@end


@implementation ViewController

//#define x265_test

#define videoname @"RaceHorses_416x240_30"
#define wpic 416
#define hpic 240
#define bitrate 500

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self Paraminit];
    self.VnameLabel.text =videoname;
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - UISetFunc
- (void)Paraminit
{
    self.filesize = 0;
    self.PlayStatus = FALSE;    //初始化按键状态为无效
#ifdef x265_test
    self.x265func = [[x265_func alloc]init];
#else
    self.x264func = [[x264_func alloc]init];
#endif
}

- (unsigned char*)videoread
{
    //construct the full name of the vedio store path
    NSString *yuvpath = [[NSBundle mainBundle] pathForResource:videoname ofType:@"yuv"];
    NSFileHandle *yuvfile = [NSFileHandle fileHandleForReadingAtPath:yuvpath];
    NSData *myData = [yuvfile readDataToEndOfFile];
    self.filesize = (int)myData.length;
    NSLog(@"filename is: %@ \n filesize is: %d", self.VnameLabel.text, (int)self.filesize);
    return (unsigned char*)[myData bytes];
}

- (void)videoencodefunc{
    int height = hpic;
    int width = wpic;
    int framesize = (height * width * 3) >> 1;
    
    unsigned char *yuvdata = [self videoread];
    
    if(self.PlayStatus)
    {
#ifdef x265_test
        x265_s_handle x265_handle = [self.x265func x265_simple_open: width :height :bitrate :yuvdata :1];
        if(x265_handle != NULL)
        {
            [self.x265func x265_simple_encode_all_frame: x265_handle :self.filesize/framesize :0];
			[self.x265func x265_simple_close: x265_handle];
        }
#else
        x264_s_handle x264_handle = [self.x264func x264_simple_open: width :height :bitrate :yuvdata :1];
        if(x264_handle != NULL)
        {
            [self.x264func x264_simple_encode_all_frame: x264_handle :self.filesize/framesize :0];
            [self.x264func x264_simple_close: x264_handle];
        }
#endif
    }
}

#pragma mark  - ButtonFunc
- (IBAction)StartBtn:(UIButton *)sender {
    self.VnameLabel.text =videoname;
    //设置播放状态为播放
    if (!self.PlayStatus) {
        self.PlayStatus = TRUE;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{[self videoencodefunc];});
    }
}

- (IBAction)StopBtn:(UIButton *)sender {
    
    self.VnameLabel.text = @" ";
    if (self.PlayStatus) {
        self.PlayStatus = FALSE;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
