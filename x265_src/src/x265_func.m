//
//  x265_func.m
//  x265_enc
//
//  Created by zhangjunhai on 16/6/14.
//  Copyright © 2016年 yy company. All rights reserved.
//

#import "x265_func.h"

@implementation x265_func

#define THREAD_COUNT 1

#define X265_PARAM_YY 1
#define X265_PRINF_FRAME_INFO 1

#define WireFile
typedef struct
{
    
    unsigned char *pdata;
    char *filename;
    
    FILE *fout;
    char *outfilenName;
    
    int pic_width;
    int pic_height;
    int pixel_format;
    
    x265_param *param;
    x265_picture *pic;
    x265_encoder *h;
    
    int64_t encode_time;
    int64_t read_enc_time;
    int enc_frame_count;
    
}x265_lib_t;

- (x265_func*)init
{
    return self;
}

static void x265_log( void *p_unused, int i_level, const char *psz_fmt, va_list args )
{
    char buf[512];
    vsnprintf(buf, 512 - 1, psz_fmt, args);
    
    buf[512 - 1] = 0;
    NSLog(@"%s",buf);
}

-(void)x265_simple_close: (x265_s_handle)handle
{
    x265_lib_t *hsimplex265 = ( x265_lib_t * )handle;
    
    if ( hsimplex265->param )
    {
        x265_param_free(hsimplex265->param);
        hsimplex265->param = NULL;
    }
    
    if ( hsimplex265->pic )
    {
        x265_picture_free(hsimplex265->pic);
        hsimplex265->pic = NULL;
        
    }
    
    if( hsimplex265->h )
    {
        x265_encoder_close( hsimplex265->h );
        hsimplex265->h = NULL;
    }
    
    if ( hsimplex265->fout )
        fclose(hsimplex265->fout );
    
    if( hsimplex265 )
        free (hsimplex265);
    
    return;
}

- (x265_s_handle)x265_simple_open: (int)width :(int)height :(int)bitrate :(unsigned char *)pdata :(int)b_psnr
{
    x265_lib_t *hsimplex265;
    x265_picture *pic ;
    x265_param *param;
    x265_encoder *h;
    //int bitrate = 1000;//1300 1000
    int fps = 20;
    int framesize = width * height;
    
    hsimplex265 = (x265_lib_t *)malloc(sizeof(x265_lib_t));
    if (hsimplex265 == NULL )
    {
        NSLog(@"x265_simple_open: malloc failed! \n");
        goto failed;
    }
    memset(hsimplex265,0,sizeof(x265_lib_t));
    
    param = x265_param_alloc();
    if(param == NULL)
    {
        NSLog(@"x264_simple_open: malloc failed! \n");
        goto failed;
    }
    hsimplex265->param = param;
    
    /* Configure non-default params */
#if X265_PARAM_YY
    if ( x265_param_default_preset(hsimplex265->param, "veryfast", "zerolatency")<0 )
    {
        NSLog(@"x264_simple_open: set param failed! \n");
        goto failed;
    }
    x265_param_apply_profile(hsimplex265->param,"main");//"main" "main10" "mainstillpicture"
    
    param->internalCsp                     = X265_CSP_I420;
    param->sourceWidth                     = width;
    param->sourceHeight                    = height;
    param->bEnablePsnr                     = b_psnr;
    
    param->fpsNum			               = fps;
    
    param->frameNumThreads                 = THREAD_COUNT;//2个线程
    param->rc.bitrate                      = bitrate;
    param->rc.rateControlMode              = X265_RC_ABR;
    param->bRepeatHeaders                  = 0;
    param->bEnableWavefront                = 1;
    param->bframes                         = 2;//没有b帧
    param->lookaheadDepth                  = 3;//没有b帧
    param->rc.vbvMaxBitrate                = param->rc.bitrate ;
    param->rc.vbvBufferSize                = param->rc.bitrate ;
    param->rc.vbvBufferInit                = 0.5;
    
    param->vui.bEnableVideoFullRangeFlag   = 0;
    param->vui.colorPrimaries              = 5;
    param->vui.transferCharacteristics     = 5;
    param->vui.matrixCoeffs                = 5;
    param->vui.bEnableVideoSignalTypePresentFlag  = 1;
    param->vui.bEnableColorDescriptionPresentFlag = 1;
    param->keyframeMax                     = 3 * fps;//i帧间隔用3秒
    param->keyframeMin                     = 3 * fps;
    param->psyRd                           = 0;
    param->rc.cuTree                       = 0;
    param->scenecutThreshold = 0;
    param->bIntraRefresh      = 0;
   
    param->logLevel = X265_LOG_INFO;
    param->fpsNum = 1;
    param->fpsDenom = 1000;
    
    param->rc.aqMode = 0;
#endif
    
    pic = x265_picture_alloc();
    x265_picture_init(param, pic);
    if(pic)
    {
        pic->stride[0] = width;
        pic->stride[1] = width/2;
        pic->stride[2] = width/2;
        pic->planes[0] = (unsigned char *)malloc(((3 * framesize) >> 1) * sizeof(unsigned char));
        pic->planes[1] = pic->planes[0] + framesize;
        pic->planes[2] = pic->planes[1] + (framesize >> 2);
    }
    hsimplex265->pic = pic;

    h = x265_encoder_open(param);
    if ( h == NULL )
    {
        NSLog(@"x265_simple_open: open encoderfailed \n");
        goto failed;
    }
    hsimplex265->h = h;
    NSLog(@"x265_simple_open: open encoder OK!\n");
    
    hsimplex265->pic_width = width;
    hsimplex265->pic_height = height;
    hsimplex265->pdata = pdata;
    if( hsimplex265->pdata == NULL )
    {
        NSLog(@"The open file is null!\n");
        goto failed;
    }
    
    x265_encoder_parameters(h, param);
    
    return hsimplex265;
failed:
    [self x265_simple_close: hsimplex265];
    return NULL;
}

- (int)x265_simple_encode_all_frame: (x265_s_handle)handle :(int)total_frame_count :(int)b_fwrite;
{
    x265_lib_t *hsimplex265 = ( x265_lib_t * )handle;
    x265_picture *pic = hsimplex265->pic;
    x265_encoder *h = hsimplex265->h;
    x265_nal *nal;
    int i_nal;
    x265_picture pic_out;
    
    int i_frame = 0;
    int ret;
    unsigned char *ydata = hsimplex265->pdata;
    
#ifdef WireFile
    NSString *FileName;
    NSFileHandle *fileHandle;
    unsigned long long FilePos = 0;
#endif
    //    FILE *fout = hsimplex264->fout;
#ifdef WireFile
    if(b_fwrite)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *sandboxPath = NSHomeDirectory();
        NSString *documentPath = [sandboxPath
                                  stringByAppendingPathComponent:@"Documents"];
        FileName = [documentPath stringByAppendingPathComponent:@"enc.x265"];
        BOOL isexist = [fileManager fileExistsAtPath:FileName];
        if(isexist)
        {
            [fileManager removeItemAtPath:FileName error:NULL];
            NSLog(@"File exist, File deleting");
        }
        [fileManager createFileAtPath:FileName contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:FileName];
    }
#endif
    
#if X265_PRINF_FRAME_INFO
    //LOGI("start enc frame %d,total %d \n",i_frame,total_frame_count);
#endif
    
    hsimplex265->encode_time = 0;
    hsimplex265->read_enc_time = 0;
    hsimplex265->enc_frame_count = 0;
    int luma_size = hsimplex265->pic_width * hsimplex265->pic_height;
    int chroma_size = luma_size / 4;
    
    for( i_frame = 0 ; i_frame < total_frame_count ; i_frame++)
    {
        
        struct timeval time_rdfile_start,time_enc_start,time_stop;
        /* Read input frame */
        gettimeofday(&time_rdfile_start, NULL);
        memcpy(pic->planes[0], ydata, luma_size * sizeof(unsigned char));
        ydata += luma_size;
        memcpy(pic->planes[1], ydata, chroma_size * sizeof(unsigned char));
        ydata += chroma_size;
        memcpy(pic->planes[2], ydata, chroma_size * sizeof(unsigned char));
        ydata += chroma_size;
        
        pic->pts = i_frame;
        
        gettimeofday(&time_enc_start, NULL);
        ret = x265_encoder_encode( h, &nal, (uint32_t *)(&i_nal), pic, &pic_out );
        gettimeofday(&time_stop, NULL);
        
        hsimplex265->encode_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_enc_start.tv_sec * 1000000.0 + time_enc_start.tv_usec);
        hsimplex265->read_enc_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_rdfile_start.tv_sec * 1000000.0 + time_rdfile_start.tv_usec);

#if X265_PRINF_FRAME_INFO
        NSLog(@"pre enc %d frame with %.2f fps!\n",i_frame, (i_frame+1) * 1000000.0/hsimplex265->encode_time);
#endif
        if( ret < 0 )
        {
            NSLog(@" encodef %d frame failed \n",i_frame);
            continue;
        }
        else if( ret )
        {
            if( b_fwrite )
            {
#ifdef WireFile
                FilePos = [fileHandle seekToEndOfFile];
                [fileHandle writeData:[NSData dataWithBytes: nal->payload
                                                     length: nal->sizeBytes]];
                //NSLog(@"Pos = %lld \n", FilePos);
#endif
            }
            
            if ( (i_frame % 100) == 0 )
                NSLog(@" encode %d frame OK! \n",i_frame );
            
            hsimplex265->enc_frame_count ++;
        }
        else
        {
            NSLog(@"no frame out!");
        }
    }

    {
        double fps = (double)hsimplex265->enc_frame_count * (double)1000000 /
        (double)( hsimplex265->encode_time );
        
        double fps_rd_enc = (double)hsimplex265->enc_frame_count * (double)1000000 /
        (double)( hsimplex265->read_enc_time );
        
        NSLog(@" encode %d frames , enc %.2f fps,read file and enc %.2f fps \n",hsimplex265->enc_frame_count,fps,fps_rd_enc);
    }
    
#ifdef WireFile
    if( b_fwrite )
    {
        [fileHandle closeFile];
        NSLog(@"Write file finished!");
    }
#endif
    
    return i_frame;
}


@end
