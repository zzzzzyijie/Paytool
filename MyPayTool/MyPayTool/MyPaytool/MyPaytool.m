//
//  MyPaytool.m
//  MyPayTool
//
//  Created by Jie on 2019/9/3.
//  Copyright © 2019 none. All rights reserved.
//

#import "MyPaytool.h"
#import <WechatOpenSDK/WXApi.h>
#import <WXApiObject.h>
#import <AlipaySDK/AlipaySDK.h>

@interface MyPaytool ()
<
WXApiDelegate
>
/** wx completeBlock */
@property (nonatomic,copy) MyPayCompleteBlock wxCompleteBlock;
/** wx completeBlock */
@property (nonatomic,copy) MyPayCompleteBlock alipayCompleteBlock;

@end

@implementation MyPaytool
/**
 *  处理微信的回调
 */
+ (BOOL)handleWxOpenURL:(NSURL *)url {
    return [[self shareInstance] handleWxCallBackWithURL:url];
}

/**
 *  处理支付宝的回调
 */
+ (BOOL)handleAlipayURL:(NSURL *)url {
    MyPaytool *payTool = [self shareInstance];
    [payTool handleAlipayCallBackWithURL:url];
    return YES;
}

/**
 *  发起支付宝支付 ( signString为签名后的字符串
 */
+ (void)alipayWithParam:(NSString *)signString completeBlock:(MyPayCompleteBlock)completeBlock {
    [[self shareInstance] privateAlipayWithParam:signString completeBlock:completeBlock];
}

/**
 *  发起微信支付 ( param微信支付所需的参数 ( WechatPayResp模型
 */
+ (void)wxpayWithParam:(NSDictionary *)param completeBlock:(MyPayCompleteBlock)completeBlock {
    [[self shareInstance] privateWxpayWithParam:param completeBlock:completeBlock];
}


#pragma mark  ---- Private Method
- (BOOL)handleWxCallBackWithURL:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:self];
}

- (void)handleAlipayCallBackWithURL:(NSURL *)url {
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        NSLog(@"result = %@",resultDic);
        if (self.alipayCompleteBlock) {
            NSString *resultStatus = resultDic[@"resultStatus"];
            if ([resultStatus isEqualToString:@"9000"]) { // 成功
                self.alipayCompleteBlock(PaySuccess);
            }else if ([resultStatus isEqualToString:@"4000"] || [resultStatus isEqualToString:@"6002"]){
                self.alipayCompleteBlock(PayFailure);
            }else if ([resultStatus isEqualToString:@"6001"]) { // 用户取消
                self.alipayCompleteBlock(PayCancel);
            } else {
                self.alipayCompleteBlock(PayFailure);
            }
        }
    }];
}

- (void)privateAlipayWithParam:(NSString *)signString completeBlock:(MyPayCompleteBlock)completeBlock {
    if (completeBlock) {
        self.alipayCompleteBlock = completeBlock;
    }
    [[AlipaySDK defaultService] payOrder:signString fromScheme:@"your scheme" callback:^(NSDictionary *resultDic) {
        NSLog(@"reslut = %@",resultDic);
        // wap 网页支付会来到这个回调
        if (self.alipayCompleteBlock) {
            NSString *resultStatus = resultDic[@"resultStatus"];
            if ([resultStatus isEqualToString:@"9000"]) { // 成功
                self.alipayCompleteBlock(PaySuccess);
            }else if ([resultStatus isEqualToString:@"4000"] || [resultStatus isEqualToString:@"6002"]){
                self.alipayCompleteBlock(PayFailure);
            }else if ([resultStatus isEqualToString:@"6001"]) { // 用户取消
                self.alipayCompleteBlock(PayCancel);
            } else {
                self.alipayCompleteBlock(PayFailure);
            }
        }
    }];
}

- (void)privateWxpayWithParam:(NSDictionary *)param completeBlock:(MyPayCompleteBlock)completeBlock {
    if (completeBlock) {
        self.wxCompleteBlock = completeBlock;
    }
    //[WXApi registerApp:WxPayAppkey]; 先注册这个
    // 这里具体的字段又后端返回而决定
    PayReq *req  = [[PayReq alloc] init];
    // 由用户微信号和AppID组成的唯一标识，用于校验微信用户
    req.openID = param[@"appid"];
    // 随机编码，为了防止重复的，在后台生成
    req.nonceStr = param[@"nonceStr"];
    // 根据财付通文档填写的数据和签名
    //这个比较特殊，是固定的，只能是即req.package = Sign=WXPay
    req.package = param[@"package"];
    // 商家id，在注册的时候给的
    req.partnerId = param[@"partnerId"];
    // 预支付订单这个是后台跟微信服务器交互后，微信服务器传给你们服务器的，你们服务器再传给你
    req.prepayId = param[@"prepayId"];
    // 这个签名也是后台做的
    req.sign = param[@"sign"];
    // 这个是时间戳，也是在后台生成的，为了验证支付的
    req.timeStamp = [param[@"timeStamp"] intValue];
    // 发送请求到微信，等待微信返回onResp
    [WXApi sendReq:req];
}

#pragma mark - WXApiDelegate
/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 */
-(void) onResp:(BaseResp*)resp {
    NSString *payResoult = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
    if([resp isKindOfClass:[PayResp class]]){
        switch (resp.errCode) {
            case 0:
                payResoult = @"支付结果：成功！";
                self.wxCompleteBlock(PaySuccess);
                break;
            case -1:
                payResoult = @"支付结果：失败！";
                self.wxCompleteBlock(PayFailure);
                break;
            case -2:
                payResoult = @"用户已经退出支付！";
                self.wxCompleteBlock(PayCancel);
                break;
            default:
                payResoult = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                self.wxCompleteBlock(PayFailure);
                break;
        }
        NSLog(@"%@",payResoult);
    }
//    else if([resp isKindOfClass:[SendAuthResp class]]) { // 同时如果使用wx授权的话 ，授权的回调也可以在这里处理
//
//    }
}


#pragma mark - 单例
static MyPaytool *_inastance = nil;
+(id)allocWithZone:(struct _NSZone *)zone{
    //调用dispatch_once保证在多线程中也只被实例化一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _inastance = [super allocWithZone:zone];
    });
    return _inastance;
}

+ (instancetype)shareInstance {
    // dispatch_once_t确保初始化器只执行一次
    static dispatch_once_t oncePredicate;
    // 单例的关键，一旦类被初始化，初始化器不会再被调用
    dispatch_once(&oncePredicate, ^{
        _inastance = [[MyPaytool alloc] init];
    });
    return _inastance;
}

/**第4步: 保证copy时都相同*/
-(id)copyWithZone:(NSZone *)zone{
    return _inastance;
}

@end
