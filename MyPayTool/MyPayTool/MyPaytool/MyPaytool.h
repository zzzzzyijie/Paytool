//
//  MyPaytool.h
//  MyPayTool
//
//  Created by Jie on 2019/9/3.
//  Copyright © 2019 none. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,MyPayStaus){
    PaySuccess,
    PayFailure,
    PayCancel
};

typedef void (^MyPayCompleteBlock)(MyPayStaus payStatus);

@interface MyPaytool : NSObject

/**
 *  处理微信的回调
 */
+ (BOOL)handleWxOpenURL:(NSURL *)url;

/**
 *  处理支付宝的回调
 */
+ (BOOL)handleAlipayURL:(NSURL *)url;

/**
 *  发起支付宝支付 ( signString为签名后的字符串
 */
+ (void)alipayWithParam:(NSString *)signString completeBlock:(MyPayCompleteBlock)completeBlock;

/**
 *  发起微信支付 ( param微信支付所需的参数 
 */
+ (void)wxpayWithParam:(NSDictionary *)param completeBlock:(MyPayCompleteBlock)completeBlock;

@end

NS_ASSUME_NONNULL_END
