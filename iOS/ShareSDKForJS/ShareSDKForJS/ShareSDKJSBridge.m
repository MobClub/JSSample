//
//  ShareSDKJSBridge.m
//  ShareSDKForJS
//
//  Created by 冯 鸿杰 on 14-3-18.
//  Copyright (c) 2014年 掌淘科技. All rights reserved.
//

#import "ShareSDKJSBridge.h"
#import <ShareSDK/ShareSDK+Utils.h>
#import <AGCommon/CMHTTPRequestParameters.h>
#import <AGCommon/UIDevice+Common.h>

#define METHOD_OPEN @"open"
#define METHOD_SET_PLAT_CONF @"setPlatformConfig"
#define METHOD_AUTH @"authorize"
#define METHOD_CANCEL_AUTH @"cancelAuthorize"
#define METHOD_HAS_AUTH @"hasAuthorized"
#define METHOD_GET_USER_INFO @"getUserInfo"
#define METHOD_SHARE_CONTENT @"shareContent"
#define METHOD_ONE_KEY_SHARE_CONTENT @"oneKeyShareContent"
#define METHOD_SHOW_SHARE_MENU @"showShareMenu"
#define METHOD_SHOW_SHARE_VIEW @"showShareView"

#define IMPORT_SINA_WEIBO_LIB               //导入新浪微博库，如果不需要新浪微博客户端分享可以注释此行
#define IMPORT_TENCENT_WEIBO_LIB            //导入腾讯微博库，如果不需要腾讯微博SSO可以注释此行
#define IMPORT_QZONE_QQ_LIB                 //导入QQ互联库，如果不需要QQ空间分享、SSO或者QQ好友分享可以注释此行
#define IMPORT_RENREN_LIB                   //导入人人库，如果不需要人人SSO，可以注释此行
#define IMPORT_GOOGLE_PLUS_LIB              //导入Google+库，如果不需要Google+分享可以注释此行
#define IMPORT_PINTEREST_LIB                //导入Pinterest库，如果不需要Pinterest分享可以注释此行
#define IMPORT_WECHAT_LIB                   //导入微信库，如果不需要微信分享可以注释此行
#define IMPORT_YIXIN_LIB                    //导入易信库，如果不需要易信分享可以注释此行

#ifdef IMPORT_SINA_WEIBO_LIB
#import "WeiboSDK.h"
#endif

#ifdef IMPORT_TENCENT_WEIBO_LIB
#import "WeiboApi.h"
#endif

#ifdef IMPORT_QZONE_QQ_LIB
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#endif

#ifdef IMPORT_RENREN_LIB
#import <RennSDK/RennSDK.h>
#endif

#ifdef IMPORT_GOOGLE_PLUS_LIB
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#endif

#ifdef IMPORT_PINTEREST_LIB
#import <Pinterest/Pinterest.h>
#endif

#ifdef IMPORT_WECHAT_LIB
#import "WXApi.h"
#endif

#ifdef IMPORT_YIXIN_LIB
#import "YXApi.h"
#endif

static ShareSDKJSBridge *_instance = nil;
static UIView *_refView = nil;

#ifdef DEBUG

@interface UIWebView (JavaScriptAlert)

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame;

@end

@implementation UIWebView (JavaScriptAlert)

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    NSLog(@"%@", message);
}

@end

#endif

@interface ShareSDKJSBridge ()
{
@private
    id<UIWebViewDelegate> _webViewDelegate;
}

@end

@implementation ShareSDKJSBridge

- (id)initWithWebView:(UIWebView *)webView
{
    if (self = [super init])
    {
        
#ifdef IMPORT_SINA_WEIBO_LIB
        [WeiboApi class];
#endif
        
#ifdef IMPORT_TENCENT_WEIBO_LIB
        [ShareSDK importTencentWeiboClass:[WeiboSDK class]];
#endif
        
#ifdef IMPORT_QZONE_QQ_LIB
        [ShareSDK importQQClass:[QQApiInterface class] tencentOAuthCls:[TencentOAuth class]];
#endif
        
#ifdef IMPORT_RENREN_LIB
        [ShareSDK importRenRenClass:[RennClient class]];
#endif
        
#ifdef IMPORT_GOOGLE_PLUS_LIB
        [ShareSDK importGooglePlusClass:[GPPSignIn class] shareClass:[GPPShare class]];
#endif
        
#ifdef IMPORT_PINTEREST_LIB
        [ShareSDK importPinterestClass:[Pinterest class]];
#endif
        
#ifdef IMPORT_WECHAT_LIB
        [ShareSDK importWeChatClass:[WXApi class]];
#endif
        
#ifdef IMPORT_YIXIN_LIB
        [ShareSDK importYiXinClass:[YXApi class]];
#endif
        
        _webViewDelegate = webView.delegate;
        webView.delegate = self;
    }
    
    return self;
}

- (BOOL)captureRequest:(NSURLRequest *)request webView:(UIWebView *)webView
{
    if ([request.URL.scheme isEqual:@"sharesdk"])
    {
        if ([request.URL.host isEqual:@"init"])
        {
            //初始化
            [webView stringByEvaluatingJavaScriptFromString:@"window.$sharesdk._init(2)"];
            
        }
        else if ([request.URL.host isEqual:@"call"])
        {
            //调用接口
            CMHTTPRequestParameters *params = [[[CMHTTPRequestParameters alloc] initWithQueryString:request.URL.query] autorelease];
            NSString *methodName = [params getValueForName:@"methodName"];
            NSString *seqId = [params getValueForName:@"seqId"];
            
            NSDictionary *paramsDict = nil;
            NSString *paramsStr = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$sharesdk._getParams(%@)",seqId]];
            if (paramsStr)
            {
                paramsDict = [ShareSDK jsonObjectWithString:paramsStr];
            }
            
            if ([methodName isEqualToString:METHOD_OPEN])
            {
                //初始化
                [self openWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_SET_PLAT_CONF])
            {
                //设置平台信息
                [self setPlatformConfigWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_AUTH])
            {
                //授权
                [self authorizeWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_CANCEL_AUTH])
            {
                //取消授权
                [self cancelAuthWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_HAS_AUTH])
            {
                //是否授权
                [self hasAuthWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_GET_USER_INFO])
            {
                //获取用户信息
                [self getUserInfoWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_SHARE_CONTENT])
            {
                //分享内容
                [self shareContentWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_ONE_KEY_SHARE_CONTENT])
            {
                //一键分享
                [self oneKeyShareContentWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_SHOW_SHARE_MENU])
            {
                //显示分享菜单
                [self showShareMenuWithSeqId:seqId params:paramsDict webView:webView];
            }
            else if ([methodName isEqualToString:METHOD_SHOW_SHARE_VIEW])
            {
                //显示分享视图
                [self showShareViewWithSeqId:seqId params:paramsDict webView:webView];
            }
            
        }
        
        return YES;
    }
    
    return NO;
}

+ (ShareSDKJSBridge *)sharedBridge
{
    @synchronized(self)
    {
        if (_instance == nil)
        {
            _instance = [[ShareSDKJSBridge alloc] init];
        }
        
        return _instance;
    }
}

+ (ShareSDKJSBridge *)bridgeWithWebView:(UIWebView *)webView
{
    return [[[ShareSDKJSBridge alloc] initWithWebView:webView] autorelease];
}

#pragma mark - Private

- (id<ISSContent>)contentWithDict:(NSDictionary *)dict
{
    NSString *message = nil;
    id<ISSCAttachment> image = nil;
    NSString *title = nil;
    NSString *url = nil;
    NSString *desc = nil;
    SSPublishContentMediaType type = SSPublishContentMediaTypeText;
    
    if (dict)
    {
        NSString *messageStr = [dict objectForKey:@"text"];
        if ([messageStr isKindOfClass:[NSString class]])
        {
            message = messageStr;
        }
        
        NSString *imagePathStr = [dict objectForKey:@"imageUrl"];
        if ([imagePathStr isKindOfClass:[NSString class]])
        {
            if ([ShareSDK isMatchWithString:imagePathStr regex:@"\\w://.*"])
            {
                image = [ShareSDK imageWithUrl:imagePathStr];
            }
            else
            {
                image = [ShareSDK imageWithPath:imagePathStr];
            }
        }
        
        NSString *titleStr = [dict objectForKey:@"title"];
        if ([titleStr isKindOfClass:[NSString class]])
        {
            title = titleStr;
        }
        
        NSString *urlStr = [dict objectForKey:@"titleUrl"];
        if ([urlStr isKindOfClass:[NSString class]])
        {
            url = urlStr;
        }
        
        NSString *descStr = [dict objectForKey:@"description"];
        if ([descStr isKindOfClass:[NSString class]])
        {
            desc = descStr;
        }
        
        NSNumber *typeValue = [dict objectForKey:@"type"];
        if ([typeValue isKindOfClass:[NSNumber class]])
        {
            type = (SSPublishContentMediaType)[typeValue integerValue];
        }
    }
    
    id<ISSContent> contentObj =  [ShareSDK content:message
                                    defaultContent:nil
                                             image:image
                                             title:title
                                               url:url
                                       description:desc
                                         mediaType:type];
    
    if (dict)
    {
        NSString *siteUrlStr = nil;
        NSString *siteStr = nil;
        
        NSString *siteUrl = [dict objectForKey:@"siteUrl"];
        if ([siteUrl isKindOfClass:[NSString class]])
        {
            siteUrlStr = siteUrl;
        }
        
        NSString *site = [dict objectForKey:@"site"];
        if ([site isKindOfClass:[NSString class]])
        {
            siteStr = site;
        }
        
        if (siteUrlStr || siteStr)
        {
            if ([ShareSDK getClientWithType:ShareTypeQQSpace])
            {
                [contentObj addQQSpaceUnitWithTitle:INHERIT_VALUE
                                                url:INHERIT_VALUE
                                               site:siteStr
                                            fromUrl:siteUrlStr
                                            comment:INHERIT_VALUE
                                            summary:INHERIT_VALUE
                                              image:INHERIT_VALUE
                                               type:INHERIT_VALUE
                                            playUrl:INHERIT_VALUE
                                               nswb:INHERIT_VALUE];
            }
        }
        
        NSString *extInfoStr = nil;
        NSString *musicUrlStr = nil;
        
        NSString *extInfo = [dict objectForKey:@"extInfo"];
        if ([extInfo isKindOfClass:[NSString class]])
        {
            extInfoStr = extInfo;
        }
        
        NSString *musicUrl = [dict objectForKey:@"musicUrl"];
        if ([musicUrl isKindOfClass:[NSString class]])
        {
            musicUrlStr = musicUrl;
        }
        
        if (extInfoStr || musicUrlStr)
        {
            if ([ShareSDK getClientWithType:ShareTypeWeixiSession])
            {
                [contentObj addWeixinSessionUnitWithType:INHERIT_VALUE
                                                 content:INHERIT_VALUE
                                                   title:INHERIT_VALUE
                                                     url:INHERIT_VALUE
                                                   image:INHERIT_VALUE
                                            musicFileUrl:musicUrlStr
                                                 extInfo:extInfoStr
                                                fileData:INHERIT_VALUE
                                            emoticonData:INHERIT_VALUE];
            }
            
            if ([ShareSDK getClientWithType:ShareTypeWeixiTimeline])
            {
                [contentObj addWeixinTimelineUnitWithType:INHERIT_VALUE
                                                  content:INHERIT_VALUE
                                                    title:INHERIT_VALUE
                                                      url:INHERIT_VALUE
                                                    image:INHERIT_VALUE
                                             musicFileUrl:musicUrlStr
                                                  extInfo:extInfoStr
                                                 fileData:INHERIT_VALUE
                                             emoticonData:INHERIT_VALUE];
            }
            
            if ([ShareSDK getClientWithType:ShareTypeWeixiFav])
            {
                [contentObj addWeixinFavUnitWithType:INHERIT_VALUE
                                             content:INHERIT_VALUE
                                               title:INHERIT_VALUE
                                                 url:INHERIT_VALUE
                                          thumbImage:INHERIT_VALUE
                                               image:INHERIT_VALUE
                                        musicFileUrl:musicUrlStr
                                             extInfo:extInfoStr
                                            fileData:INHERIT_VALUE
                                        emoticonData:INHERIT_VALUE];
            }
        }
    }
    
    return contentObj;
}

/**
 *	@brief	返回数据
 *
 *	@param 	data 	回复数据
 *	@param 	webView 	Web视图
 */
- (void)resultWithData:(NSDictionary *)data webView:(UIWebView *)webView
{
    NSLog(@"%@", [NSString stringWithFormat:@"$sharesdk._callback(%@)", [ShareSDK jsonStringWithObject:data]]);
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$sharesdk._callback(%@)", [ShareSDK jsonStringWithObject:data]]];
}

/**
 *	@brief	初始化SDK
 *
 *	@param 	seqId 	流水号
 *	@param 	params 	参数
 *  @param  webView Web视图
 */
- (void)openWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    NSString *appKey = nil;
    if ([[params objectForKey:@"appKey"] isKindOfClass:[NSString class]])
    {
        appKey = [params objectForKey:@"appKey"];
    }
    [ShareSDK registerApp:appKey];
    
    BOOL statEnable = YES;
    if ([[params objectForKey:@"enableStatistics"] isKindOfClass:[NSNumber class]])
    {
        statEnable = [[params objectForKey:@"enableStatistics"] boolValue];
    }
    [ShareSDK statEnabled:statEnable];
    
    //返回
    NSDictionary *responseDict = @{@"seqId": [NSNumber numberWithInteger:[seqId integerValue]],
                                   @"method" : METHOD_OPEN,
                                   @"state" : [NSNumber numberWithInteger:SSResponseStateSuccess]};
    [self resultWithData:responseDict webView:webView];
}

/**
 *	@brief	设置平台配置
 *
 *	@param 	seqId 	流水号
 *	@param 	params 	参数
 *  @param  webView Web视图
 */
- (void)setPlatformConfigWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    NSMutableDictionary *config = nil;
    
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    if ([[params objectForKey:@"config"] isKindOfClass:[NSDictionary class]])
    {
        config = [NSMutableDictionary dictionaryWithDictionary:[params objectForKey:@"config"]];
    }
    
    switch (type)
    {
        case ShareTypeWeixiSession:
        case ShareTypeYiXinSession:
            [config setObject:[NSNumber numberWithInt:0] forKey:@"scene"];
            break;
        case ShareTypeWeixiTimeline:
        case ShareTypeYiXinTimeline:
            [config setObject:[NSNumber numberWithInt:1] forKey:@"scene"];
            break;
        case ShareTypeWeixiFav:
            [config setObject:[NSNumber numberWithInt:2] forKey:@"scene"];
            break;
        default:
            break;
    }
    
    [ShareSDK connectPlatformWithType:type platform:nil appInfo:config];
    
    //返回
    NSDictionary *responseDict = @{@"seqId": [NSNumber numberWithInteger:[seqId integerValue]],
                                   @"method" : METHOD_SET_PLAT_CONF,
                                   @"state" : [NSNumber numberWithInteger:SSResponseStateSuccess],
                                   @"platform" : [NSNumber numberWithInteger:type]};
    [self resultWithData:responseDict webView:webView];
}

/**
 *	@brief	用户授权
 *
 *	@param 	seqId 	流水号
 *	@param 	params 	参数
 *  @param  webView Web视图
 */
- (void)authorizeWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK authWithType:type options:nil result:^(SSAuthState state, id<ICMErrorInfo> error) {
       
        //返回
        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInteger:[seqId integerValue]],
                                             @"seqId",
                                             METHOD_AUTH,
                                             @"method",
                                             [NSNumber numberWithInteger:state],
                                             @"state",
                                             [NSNumber numberWithInteger:type],
                                             @"platform",
                                             callback,
                                             @"callback",
                                             nil];
        if (error)
        {
            [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:[error errorLevel]],
                                     @"error_level",
                                     [NSNumber numberWithInteger:[error errorCode]],
                                     @"error_code",
                                     [error errorDescription],
                                     @"error_msg",
                                     nil]
                             forKey:@"error"];
        }
        
        [self resultWithData:responseDict webView:webView];
        
    }];
}

- (void)cancelAuthWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    [ShareSDK cancelAuthWithType:type];
    
    //返回
    NSDictionary *responseDict = @{@"seqId": [NSNumber numberWithInteger:[seqId integerValue]],
                                   @"method" : METHOD_CANCEL_AUTH,
                                   @"state" : [NSNumber numberWithInteger:SSResponseStateSuccess],
                                   @"platform" : [NSNumber numberWithInteger:type]};
    [self resultWithData:responseDict webView:webView];
}

- (void)hasAuthWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    BOOL ret = [ShareSDK hasAuthorizedWithType:type];
    
    //返回
    NSDictionary *responseDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInteger:[seqId integerValue]],
                                  @"seqId",
                                  METHOD_HAS_AUTH,
                                  @"method",
                                  [NSNumber numberWithInteger:SSResponseStateSuccess],
                                  @"state",
                                  [NSNumber numberWithInteger:type],
                                  @"platform",
                                  [NSNumber numberWithBool:ret],
                                  @"data",
                                  callback,
                                  @"callback",
                                  nil];
    
    [self resultWithData:responseDict webView:webView];
}

- (void)getUserInfoWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK getUserInfoWithType:type
                      authOptions:nil
                           result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
                               
                               //返回
                               NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithInteger:[seqId integerValue]],
                                                                    @"seqId",
                                                                    METHOD_GET_USER_INFO,
                                                                    @"method",
                                                                    [NSNumber numberWithInteger:(result ? SSResponseStateSuccess : SSResponseStateFail)],
                                                                    @"state",
                                                                    [NSNumber numberWithInteger:type],
                                                                    @"platform",
                                                                    callback,
                                                                    @"callback",
                                                                    nil];
                               if (error)
                               {
                                   [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [NSNumber numberWithInteger:[error errorLevel]],
                                                            @"error_level",
                                                            [NSNumber numberWithInteger:[error errorCode]],
                                                            @"error_code",
                                                            [error errorDescription],
                                                            @"error_msg",
                                                            nil]
                                                    forKey:@"error"];
                               }
                               
                               if ([userInfo sourceData])
                               {
                                   [responseDict setObject:[userInfo sourceData] forKey:@"data"];
                               }
                               
                               [self resultWithData:responseDict webView:webView];
                               
                           }];
}

- (void)shareContentWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    id<ISSContent> content = nil;
    if ([[params objectForKey:@"shareParams"] isKindOfClass:[NSDictionary class]])
    {
        content = [self contentWithDict:[params objectForKey:@"shareParams"]];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK shareContent:content
                      type:type
               authOptions:nil
              shareOptions:nil
             statusBarTips:NO
                    result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                        
                        //返回
                        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithInteger:[seqId integerValue]],
                                                             @"seqId",
                                                             METHOD_SHARE_CONTENT,
                                                             @"method",
                                                             [NSNumber numberWithInteger:state],
                                                             @"state",
                                                             [NSNumber numberWithInteger:type],
                                                             @"platform",
                                                             [NSNumber numberWithBool:end],
                                                             @"end",
                                                             callback,
                                                             @"callback",
                                                             nil];
                        if (error)
                        {
                            [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInteger:[error errorLevel]],
                                                     @"error_level",
                                                     [NSNumber numberWithInteger:[error errorCode]],
                                                     @"error_code",
                                                     [error errorDescription],
                                                     @"error_msg",
                                                     nil]
                                             forKey:@"error"];
                        }
                        
                        if ([statusInfo sourceData])
                        {
                            [responseDict setObject:[statusInfo sourceData] forKey:@"data"];
                        }
                        
                        [self resultWithData:responseDict webView:webView];
                        
                    }];
}

- (void)oneKeyShareContentWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    NSArray *types = nil;
    if ([[params objectForKey:@"platforms"] isKindOfClass:[NSArray class]])
    {
        types = [params objectForKey:@"platforms"];
    }
    
    id<ISSContent> content = nil;
    if ([[params objectForKey:@"shareParams"] isKindOfClass:[NSDictionary class]])
    {
        content = [self contentWithDict:[params objectForKey:@"shareParams"]];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK oneKeyShareContent:content
                       shareList:types
                     authOptions:nil
                    shareOptions:nil
                   statusBarTips:NO
                          result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                              
                              //返回
                              NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSNumber numberWithInteger:[seqId integerValue]],
                                                                   @"seqId",
                                                                   METHOD_ONE_KEY_SHARE_CONTENT,
                                                                   @"method",
                                                                   [NSNumber numberWithInteger:state],
                                                                   @"state",
                                                                   [NSNumber numberWithInteger:type],
                                                                   @"platform",
                                                                   [NSNumber numberWithBool:end],
                                                                   @"end",
                                                                   callback,
                                                                   @"callback",
                                                                   nil];
                              if (error)
                              {
                                  [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInteger:[error errorLevel]],
                                                           @"error_level",
                                                           [NSNumber numberWithInteger:[error errorCode]],
                                                           @"error_code",
                                                           [error errorDescription],
                                                           @"error_msg",
                                                           nil]
                                                   forKey:@"error"];
                              }
                              
                              if ([statusInfo sourceData])
                              {
                                  [responseDict setObject:[statusInfo sourceData] forKey:@"data"];
                              }
                              
                              [self resultWithData:responseDict webView:webView];
                              
                          }];
}

- (void)showShareMenuWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    NSArray *types = nil;
    if ([[params objectForKey:@"platforms"] isKindOfClass:[NSArray class]])
    {
        types = [params objectForKey:@"platforms"];
    }
    
    id<ISSContent> content = nil;
    if ([[params objectForKey:@"shareParams"] isKindOfClass:[NSDictionary class]])
    {
        content = [self contentWithDict:[params objectForKey:@"shareParams"]];
    }
    
    CGFloat x = 0;
    if ([[params objectForKey:@"x"] isKindOfClass:[NSNumber class]])
    {
        x = [[params objectForKey:@"x"] floatValue];
    }
    
    CGFloat y = 0;
    if ([[params objectForKey:@"y"] isKindOfClass:[NSNumber class]])
    {
        y = [[params objectForKey:@"y"] floatValue];
    }
    
    UIPopoverArrowDirection direction = UIPopoverArrowDirectionAny;
    if ([[params objectForKey:@"direction"] isKindOfClass:[NSNumber class]])
    {
        direction = (UIPopoverArrowDirection)[[params objectForKey:@"direction"] integerValue];
    }
    
    id<ISSContainer> container = nil;
    if ([UIDevice currentDevice].isPad)
    {
        UIViewController *vc = [ShareSDK currentViewController];
        
        if (!_refView)
        {
            _refView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        }
        
        _refView.frame = CGRectMake(x, y, 1, 1);
        [_refView removeFromSuperview];
        [vc.view addSubview:_refView];
        
        container = [ShareSDK container];
        [container setIPadContainerWithView:_refView arrowDirect:direction];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK showShareActionSheet:container
                         shareList:types
                           content:content
                     statusBarTips:NO
                       authOptions:nil
                      shareOptions:nil
                            result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                               
                                //返回
                                NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSNumber numberWithInteger:[seqId integerValue]],
                                                                     @"seqId",
                                                                     METHOD_SHOW_SHARE_MENU,
                                                                     @"method",
                                                                     [NSNumber numberWithInteger:state],
                                                                     @"state",
                                                                     [NSNumber numberWithInteger:type],
                                                                     @"platform",
                                                                     [NSNumber numberWithBool:end],
                                                                     @"end",
                                                                     callback,
                                                                     @"callback",
                                                                     nil];
                                if (error)
                                {
                                    [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithInteger:[error errorLevel]],
                                                             @"error_level",
                                                             [NSNumber numberWithInteger:[error errorCode]],
                                                             @"error_code",
                                                             [error errorDescription],
                                                             @"error_msg",
                                                             nil]
                                                     forKey:@"error"];
                                }
                                
                                if ([statusInfo sourceData])
                                {
                                    [responseDict setObject:[statusInfo sourceData] forKey:@"data"];
                                }
                                
                                [self resultWithData:responseDict webView:webView];
                                
                                if (_refView)
                                {
                                    [_refView removeFromSuperview];
                                }
                            }];
    
}

- (void)showShareViewWithSeqId:(NSString *)seqId params:(NSDictionary *)params webView:(UIWebView *)webView
{
    ShareType type = ShareTypeAny;
    if ([[params objectForKey:@"platform"] isKindOfClass:[NSNumber class]])
    {
        type = (ShareType)[[params objectForKey:@"platform"] integerValue];
    }
    
    id<ISSContent> content = nil;
    if ([[params objectForKey:@"shareParams"] isKindOfClass:[NSDictionary class]])
    {
        content = [self contentWithDict:[params objectForKey:@"shareParams"]];
    }
    
    NSString *callback = nil;
    if ([[params objectForKey:@"callback"] isKindOfClass:[NSString class]])
    {
        callback = [params objectForKey:@"callback"];
    }
    
    [ShareSDK showShareViewWithType:type
                          container:nil
                            content:content
                      statusBarTips:NO
                        authOptions:nil
                       shareOptions:nil
                             result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                                 
                                 //返回
                                 NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                      [NSNumber numberWithInteger:[seqId integerValue]],
                                                                      @"seqId",
                                                                      METHOD_SHOW_SHARE_VIEW,
                                                                      @"method",
                                                                      [NSNumber numberWithInteger:state],
                                                                      @"state",
                                                                      [NSNumber numberWithInteger:type],
                                                                      @"platform",
                                                                      [NSNumber numberWithBool:end],
                                                                      @"end",
                                                                      callback,
                                                                      @"callback",
                                                                      nil];
                                 if (error)
                                 {
                                     [responseDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [NSNumber numberWithInteger:[error errorLevel]],
                                                              @"error_level",
                                                              [NSNumber numberWithInteger:[error errorCode]],
                                                              @"error_code",
                                                              [error errorDescription],
                                                              @"error_msg",
                                                              nil]
                                                      forKey:@"error"];
                                 }
                                 
                                 if ([statusInfo sourceData])
                                 {
                                     [responseDict setObject:[statusInfo sourceData] forKey:@"data"];
                                 }
                                 
                                 [self resultWithData:responseDict webView:webView];
                                 
                             }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self captureRequest:request webView:webView])
    {
        //捕获请求
        return NO;
    }
    
    if ([_webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
    {
        return [_webViewDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([_webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [_webViewDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [_webViewDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [_webViewDelegate webView:webView didFailLoadWithError:error];
    }
}

@end
