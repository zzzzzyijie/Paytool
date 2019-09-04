# Paytool
简单对微信支付&amp;支付宝支付的封装

- 资料 

    [WX开放平台](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317851&token=&lang=zh_CN)
    [QQ互联](http://wiki.connect.qq.com/)


### 为什么要对支付的封装？

```
虽然支付宝、微信等SDK对支付的封装已经很好了。
但如果在项目中直接使用，还是会出现一些问题，如：

1.当调用微信或支付宝的时候还是需要配置一堆参数（微信）、和处理一堆状态（支付宝），这不是我们希望的。

2.另外，一般项目中涉及到支付的地方可能有很多处地方，如果每处地方都这样写，那这些代码就重复了。

所以，对这些SDK的封装很有必要。
```

### 怎么去封装？
```
对于SDK的封装，其实可以参考其他的SDK，例如Ping++就是对各种支付渠道的封装，以及类似友盟对第三方登录等的封装，
可以了解一下别人怎么去封装。

我个人觉得，首先，要符合需求，其次使用起来比较爽。

那对于支付，我只需要关心【传的参数】、以及处理回调的结果。

比如这样： [PayTool wxPayWithParam:param completeBlock {
                if （success）{
                    // 成功
                }else if (failure) {
                    // 失败
                }else if (cancel) {
                    // 取消 
                }....
           ]

同时 ，还需要处理handleOpenURL等，所以暴露个方法处理即可

```

### 实践
```
1.创建MyPaytool类，使用一个全局单例吧

2.暴露handleURL方法，在Appdelegate使用
  如：
  @interface MyPaytool: NSObject
    /**
     *  处理微信的回调
     */
    + (BOOL)handleWxOpenURL:(NSURL *)url;
    
    /**
     *  处理支付宝的回调
     */
    + (BOOL)handleAlipayURL:(NSURL *)url;
    
    ...
    
  @end

  Appdelegate.m
    // 处理回调
    - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
        NSString *scheme = url.scheme;
        if ([scheme isEqualToString:@""]) { // 微信
            return [MyPaytool handleWxOpenURL:url];
        } else if ([url.host isEqualToString:@"safepay"]) { // 支付宝
            return [MyPaytool handleAlipayURL:url];
        }else {
            // 其他 ...
            return YES;
        }
    }


2. 支付调用

  @interface MyPaytool: NSObject
    
    ...
    
    /**
     *  发起支付宝支付 ( signString为签名后的字符串
     */
    + (void)alipayWithParam:(NSString *)signString completeBlock:(MyPayCompleteBlock)completeBlock;
    
    /**
     *  发起微信支付 ( param微信支付所需的参数 
     */
    + (void)wxpayWithParam:(NSDictionary *)param completeBlock:(MyPayCompleteBlock)completeBlock;
    
  @end
  
    
    @implementation MyPaytool
        在 .m 里调用微信和支付宝sdk即可
    @end


3.处理回调
    首先，在工具类中定义了回调的状态以及block,如：
    （通常提示这几种即可）
    typedef NS_ENUM(NSInteger,MyPayStaus){
        PaySuccess,
        PayFailure,
        PayCancel
    };
    
    typedef void (^MyPayCompleteBlock)(MyPayStaus payStatus);
    
    支付宝（block）：
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
    
    微信（代理）：
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
    } 
    
至此，那简单封装完毕了。
```

