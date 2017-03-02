//
//  x264_func.h
//  x264_enc
//
//  Created by zhangjunhai on 16/6/14.
//  Copyright © 2016年 yy company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "x264.h"
#include <sys/time.h>

typedef void* x264_s_handle;
char *x264_param2string(x264_param_t *p,int b_res);

@interface x264_func : NSObject
- (x264_s_handle)x264_simple_open: (int)width :(int)height :(int)bitrate :(unsigned char *)pdata :(int)b_psnr;
- (int)x264_simple_encode_all_frame: (x264_s_handle)handle :(int)total_frame_count :(int)b_fwrite;
- (void)x264_simple_close: (x264_s_handle)handle;
@end
