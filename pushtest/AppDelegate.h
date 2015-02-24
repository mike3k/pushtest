//
//  AppDelegate.h
//  pushtest
//
//  Created by Mike Cohen on 2/20/15.
//  Copyright (c) 2015 Mike Cohen. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <PushKit/PushKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSData *deviceToken;
@property (assign, nonatomic) NSInteger userid;
@property (strong,nonatomic) NSString *ticket;
@end

