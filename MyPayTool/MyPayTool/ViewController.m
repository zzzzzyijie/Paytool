//
//  ViewController.m
//  MyPayTool
//
//  Created by Jie on 2019/9/3.
//  Copyright © 2019 none. All rights reserved.
//

#import "ViewController.h"
#import "MyPaytool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [MyPaytool alipayWithParam:@"" completeBlock:^(MyPayStaus payStatus) {
        
    }];
}


@end
