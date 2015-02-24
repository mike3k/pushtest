//
//  ViewController.m
//  pushtest
//
//  Created by Mike Cohen on 2/20/15.
//  Copyright (c) 2015 Mike Cohen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMsg:) name:@"showMsg" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showMsg:(NSNotification*)notification {
    NSString *msg = [notification object];
    self.textview.text = msg;
}

@end
