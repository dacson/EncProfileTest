//
//  x264_func.m
//  x264_enc
//
//  Created by zhangjunhai on 16/6/14.
//  Copyright © 2016年 yy company. All rights reserved.
//

#import "x264_func.h"

@implementation x264_func

#define THREAD_COUNT 1

#define X264_PARAM_YY 1
#define X264_PRINF_FRAME_INFO 1

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
    
    x264_param_t *param;
    x264_picture_t *pic;
    x264_t *h;
    
    int64_t encode_time;
    int64_t read_enc_time;
    int enc_frame_count;
    
}x264_lib_t;

- (x264_func*)init
{
    return self;
}

static void x264_log( void *p_unused, int i_level, const char *psz_fmt, va_list args )
{
    char buf[512];
    vsnprintf(buf, 512 - 1, psz_fmt, args);
    
    buf[512 - 1] = 0;
    NSLog(@"%s",buf);
}

-(void)x264_simple_close: (x264_s_handle)handle
{
    x264_lib_t *hsimplex264 = ( x264_lib_t * )handle;
    
    if ( hsimplex264->param )
    {
        free( hsimplex264->param );
        hsimplex264->param = NULL;
    }
    
    if ( hsimplex264->pic )
    {
        x264_picture_clean( hsimplex264->pic );
        free ( hsimplex264->pic );
        hsimplex264->pic = NULL;
        
    }
    
    if( hsimplex264->h )
    {
        x264_encoder_close( hsimplex264->h );
        hsimplex264->h = NULL;
    }
    
    if ( hsimplex264->fout )
        fclose(hsimplex264->fout );
    
    if( hsimplex264 )
        free (hsimplex264);
    
    return;
}

- (x264_s_handle)x264_simple_open: (int)width :(int)height :(int)bitrate :(unsigned char *)pdata :(int)b_psnr
{
    x264_lib_t *hsimplex264;
    x264_param_t *param;
    x264_picture_t *pic ;
    x264_t *h;
    //int bitrate = 1000;//1300 1000
    int fps = 30;
    char *paramString;
    
    hsimplex264 = (x264_lib_t *)malloc(sizeof(x264_lib_t));
    if (hsimplex264 == NULL )
    {
        NSLog(@"x264_simple_open: malloc failed! \n");
        goto failed;
    }
    memset(hsimplex264,0,sizeof(x264_lib_t));
    
    param = (x264_param_t *)malloc(sizeof(x264_param_t));
    if(param == NULL)
    {
        NSLog(@"x264_simple_open: malloc failed! \n");
        goto failed;
    }
    hsimplex264->param = param;
    
    /* Configure non-default params */
#if X264_PARAM_YY
    if ( x264_param_default_preset(param, "yyveryfast", "zerolatency")<0 )
    {
        NSLog(@"x264_simple_open: set param failed! \n");
        goto failed;
    }
    x264_param_apply_profile(param,"high");//"baseline" "main" "high"
    
    param->i_csp = X264_CSP_I420;
    param->i_width  = width;
    param->i_height = height;
    param->analyse.b_psnr = b_psnr;
    
    param->i_fps_num			 = fps;
    param->i_fps_den			 = 1;
    param->i_slice_count         = 0;
    
    param->i_threads            = THREAD_COUNT;//2个线程
    param->b_sliced_threads     = 1;
    param->b_deterministic      = 1;
    param->i_bframe             = 2;//没有b帧
    
    param->rc.i_lookahead		 = 0;//码率设置严格
    //param->rc.i_rc_method       = X264_RC_CRF;
    param->rc.f_rf_constant     = 23;
    param->rc.i_qp_max          = 50;
    param->rc.i_qp_min          = 12;
    param->rc.i_qp_step         = 4;
    
    param->rc.i_bitrate	     = bitrate;
    //param->rc.i_vbv_max_bitrate = bitrate;
    param->rc.f_rate_tolerance = 0.1;
    //param->rc.i_vbv_buffer_size = param->rc.i_vbv_max_bitrate*2;
    //param->rc.f_vbv_buffer_init = 0.5;
    param->b_vfr_input = 0;
    
    param->vui.b_fullrange = 0;
    param->vui.i_colorprim = 5;
    param->vui.i_transfer = 5;
    param->vui.i_colmatrix = 5;
    param->rc.b_mb_tree = 0;
    
    param->i_keyint_max         = 150;//i帧间隔用3秒
    param->i_keyint_min         = 150;
    
    param->i_scenecut_threshold = 0;
    param->b_intra_refresh      = 0;
   
    //param->pf_log = x264_log;
    param->p_log_private = NULL;
    param->i_log_level = X264_LOG_INFO;
    param->b_vfr_input = 0;
    param->i_timebase_num = 1;
    param->i_timebase_den = 1000;
    param->b_repeat_headers = 1;
    
    //linsm test
    //baseline 相关
    //param->analyse.b_transform_8x8 = 1;
    // param->b_cabac = 1;
    //param->analyse.i_weighted_pred = X264_WEIGHTP_SIMPLE; //X264_WEIGHTP_NONE X264_WEIGHTP_SIMPLE
    
    //superfast - ultrafast
    //param->rc.i_aq_mode = 0;
    //param->b_deblocking_filter = 0;
    //param->analyse.i_subpel_refine = 4; // 0 1 2 4 6,test
    //param->analyse.intra = 0; //X264_ANALYSE_I8x8 (yysuperfast) //0 ultrafast
    //param->analyse.inter =  0;//X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;(superfast) //0 (ultrafast)
    //param->analyse.inter =  X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;// (superfast, default)
    //param->analyse.intra = X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;//medium
    //param->analyse.inter = X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8
    //                   | X264_ANALYSE_PSUB16x16 | X264_ANALYSE_BSUB16x16; //(medium)
    
    //other
    //param->i_scenecut_threshold = 0;
    //param->i_frame_reference = 3;
    //param->analyse.i_me_range = 8;
    //param->i_scenecut_threshold = 0;
    //param->analyse.i_trellis = 1;
    //param->analyse.b_mixed_references = 1;
    //param->analyse.b_chroma_me = 0;
    
    //param->analyse.inter = X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;
    //param->i_bframe             = 2;//没有b帧
    //param->i_bframe_adaptive = 0;
    //param->i_bframe_pyramid = 0;
    //param->analyse.i_subpel_refine = 2;
    
    #if 0
    param->analyse.b_fast_mode_decision_hdp = 1;
    param->analyse.i_hdp_th_percentage = 75;//higher->faster, range 0~800
    param->analyse.i_me_method = X264_ME_CET2;
    param->analyse.b_fast_hpel = 1;
    param->analyse.i_try_hpel_threshold = 2000;
    param->analyse.b_fast_qpel = 1;
    param->analyse.b_fast_slicetype = 1;
    param->analyse.i_slicetype_me_refine = 0;
    param->analyse.b_fast_slicetype_intra = 1;
    param->analyse.b_force_fast_skip_p = 1;
    param->analyse.b_force_fast_skip_b = 1;
    #endif
    
    param->rc.i_aq_mode = 0;
    param->analyse.b_psy = 0;
    
    #if 0
    //param superfast
    //param->analyse.inter =  0;//X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;(superfast) //0 (ultrafast) 16x16 now
    //param->analyse.i_subpel_refine = 1;//not modify here
    //param->rc.i_lookahead = 0; //zerolatency have set
    //param->rc.b_mb_tree = 0;   //zerolatency have set
    //param->analyse.i_me_method = X264_ME_DIA;
    
    //ualtra fast
    param->analyse.i_weighted_pred = X264_WEIGHTP_NONE;
    param->analyse.b_weighted_bipred = 0;
    param->i_scenecut_threshold = 0;
    param->i_bframe_adaptive = 0;
    
    //param modify
    param->b_cabac = 1;
    param->analyse.b_transform_8x8 = 1;
    param->analyse.i_subpel_refine = 1;
    param->analyse.inter = 0;//X264_ANALYSE_I4x4 | X264_ANALYSE_I8x8;(superfast) //0 (ultrafast) 16x16 now
    param->analyse.i_me_method = X264_ME_DIA;
    param->rc.i_aq_mode = 0;
    param->analyse.b_psy = 0;
    param->analyse.i_trellis = 0;
    #endif
    
    NSLog(@"look ahead %d frames,mb tree %d !\n",param->rc.i_lookahead,param->rc.b_mb_tree );
    NSLog(@"i trellis %d ,b_mixed_references %d !\n",param->analyse.i_trellis,param->analyse.b_mixed_references );
#endif
    
    pic = (x264_picture_t *)malloc(sizeof(x264_picture_t));
    if(pic == NULL )
    {
        NSLog(@"x264_simple_open: malloc failed! \n");
        goto failed;
    }
    hsimplex264->pic = pic;
    NSLog(@"@x264_simple_open: handle creat OK \n");
    
    if( x264_picture_alloc( pic, param->i_csp, param->i_width, param->i_height ) < 0 )
    {
        NSLog(@"x264_simple_open: alloc pic failed \n");
        goto failed;
    }
    NSLog(@"x264_simple_open: pic creat OK \n");
    
    h = x264_encoder_open( param );
    if ( h == NULL )
    {
        NSLog(@"x264_simple_open: open encoderfailed \n");
        goto failed;
    }
    hsimplex264->h = h;
    NSLog(@"x264_simple_open: open encoder OK!\n");
    
    hsimplex264->pic_width = width;
    hsimplex264->pic_height = height;
    
    hsimplex264->pdata = pdata;
    if( hsimplex264->pdata == NULL )
    {
        NSLog(@"The open file is null!\n");
        goto failed;
    }
    
    //hsimplex264->fout = fopen("/storage/sdcard0/enc.264","wb");
    //if( hsimplex264->fout == NULL )
    //{
    //    NSLog(@" open out file failed !\n");
    //    goto failed;
    //}
    x264_encoder_parameters(h, param);
    paramString = x264_param2string(param,1);
    NSLog(@"%s \n",paramString);
    
    return hsimplex264;
failed:
    [self x264_simple_close: hsimplex264];
    return NULL;
}

- (int)x264_simple_encode_all_frame: (x264_s_handle)handle :(int)total_frame_count :(int)b_fwrite;
{
    x264_lib_t *hsimplex264 = ( x264_lib_t * )handle;
    x264_picture_t *pic = hsimplex264->pic;
    x264_t *h = hsimplex264->h;
    x264_nal_t *nal;
    int i_nal;
    x264_picture_t pic_out;
    
    int i_frame = 0;
    int i_frame_size;
    unsigned char *ydata = hsimplex264->pdata;
    
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
        FileName = [documentPath stringByAppendingPathComponent:@"enc.264"];
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
    
#if X264_PRINF_FRAME_INFO
    //LOGI("start enc frame %d,total %d \n",i_frame,total_frame_count);
#endif
    
    hsimplex264->encode_time = 0;
    hsimplex264->read_enc_time = 0;
    hsimplex264->enc_frame_count = 0;
    int luma_size = hsimplex264->pic_width * hsimplex264->pic_height;
    int chroma_size = luma_size / 4;
    
    for( i_frame = 0 ; i_frame < total_frame_count ; i_frame++)
    {
        
        struct timeval time_rdfile_start,time_enc_start,time_stop;
        
        /* Read input frame */
        gettimeofday(&time_rdfile_start, NULL);
        memcpy(pic->img.plane[0], ydata, luma_size * sizeof(unsigned char));
        ydata += luma_size;
        memcpy(pic->img.plane[1], ydata, chroma_size * sizeof(unsigned char));
        ydata += chroma_size;
        memcpy(pic->img.plane[2], ydata, chroma_size * sizeof(unsigned char));
        ydata += chroma_size;
        
        pic->i_pts = i_frame;
        
        gettimeofday(&time_enc_start, NULL);
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, pic, &pic_out );
        gettimeofday(&time_stop, NULL);
        
        hsimplex264->encode_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_enc_start.tv_sec * 1000000.0 + time_enc_start.tv_usec);
        hsimplex264->read_enc_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_rdfile_start.tv_sec * 1000000.0 + time_rdfile_start.tv_usec);

#if X264_PRINF_FRAME_INFO
        NSLog(@"pre enc %d frame with %.2f fps!\n",i_frame, (i_frame+1) * 1000000.0/hsimplex264->encode_time);
#endif
        
        if( i_frame_size < 0 )
        {
            NSLog(@" encodef %d frame failed \n",i_frame);
            continue;
        }
        else if( i_frame_size )
        {
            if( b_fwrite )
            {
#ifdef WireFile
                FilePos = [fileHandle seekToEndOfFile];
                [fileHandle writeData:[NSData dataWithBytes: nal->p_payload
                                                     length: i_frame_size]];
                //NSLog(@"Pos = %lld \n", FilePos);
#endif
            }
            
            if ( (i_frame % 100) == 0 )
                NSLog(@" encode %d frame OK! \n",i_frame );
            
            hsimplex264->enc_frame_count ++;
        }
        else
        {
            NSLog(@"no frame out!");
        }
    }
    /* Flush delayed frames */
    
    while( x264_encoder_delayed_frames( h ) )
    {
        
        struct timeval time_enc_start,time_stop;
        
        gettimeofday(&time_enc_start, NULL);
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, NULL, &pic_out );
        gettimeofday(&time_stop, NULL);

        hsimplex264->encode_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_enc_start.tv_sec * 1000000.0 + time_enc_start.tv_usec);
        hsimplex264->read_enc_time += (time_stop .tv_sec * 1000000.0 + time_stop.tv_usec) - (time_enc_start.tv_sec * 1000000.0 + time_enc_start.tv_usec);
        
        if( i_frame_size < 0 )
        {
            NSLog(@" encodef %d frame failed \n",i_frame);
            continue;
        }
        else if( i_frame_size )
        {
            if( b_fwrite )
            {
#ifdef WireFile
                FilePos = [fileHandle seekToEndOfFile];
                [fileHandle writeData:[NSData dataWithBytes: nal->p_payload
                                                     length: i_frame_size]];
                //NSLog(@"Pos = %lld \n", FilePos);
#endif
            }
            
            NSLog(@" encode delayed frame OK! \n" );
            hsimplex264->enc_frame_count ++;
        }
    }
    
    {
        double fps = (double)hsimplex264->enc_frame_count * (double)1000000 /
        (double)( hsimplex264->encode_time );
        
        double fps_rd_enc = (double)hsimplex264->enc_frame_count * (double)1000000 /
        (double)( hsimplex264->read_enc_time );
        
        NSLog(@" encode %d frames , enc %.2f fps,read file and enc %.2f fps \n",hsimplex264->enc_frame_count,fps,fps_rd_enc);
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
