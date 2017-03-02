//
//  x264_func.h
//  x264_enc
//
//  Created by zhangjunhai on 16/6/14.
//  Copyright © 2016年 yy company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "x265.h"
#include <sys/time.h>

typedef void* x265_s_handle;
char *x265_param2string(x265_param *p,int b_res);

@interface x265_func : NSObject
- (x265_s_handle)x265_simple_open: (int)width :(int)height :(int)bitrate :(unsigned char *)pdata :(int)b_psnr;
- (int)x265_simple_encode_all_frame: (x265_s_handle)handle :(int)total_frame_count :(int)b_fwrite;
- (void)x265_simple_close: (x265_s_handle)handle;
@end
