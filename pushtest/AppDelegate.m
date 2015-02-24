//
//  AppDelegate.m
//  pushtest
//
//  Created by Mike Cohen on 2/20/15.
//  Copyright (c) 2015 Mike Cohen. All rights reserved.
//

#import "AppDelegate.h"

@interface NSData (deviceToken)

- (NSString*)hexString;

@end

@implementation NSData (deviceToken)

- (NSString*)hexString {
    const unsigned *tokenBytes = [self bytes];
    NSString *hexString = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    return hexString;
}


@end


@interface AppDelegate ()

- (void)sendRequest:(NSString*)path
             method:(NSString*)method
               body:(NSDictionary*)body
         completion:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completion;

@end

@implementation AppDelegate

static const NSString * base_url = @"http://7f03b67ca2c84eec8ba0c3d550e74b99.cloudapp.net/";

- (void)sendRequest:(NSString*)path
             method:(NSString*)method
               body:(NSDictionary*)body
         completion:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completion {
    
    NSError *error = nil;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",base_url,path]]];
    request.HTTPMethod = method;
    request.allHTTPHeaderFields = @{@"Accept": @"application/json", @"Content-type": @"application/json"};
    if (body) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        if (nil != error) {
            (completion)(nil,nil,error);
            return;
        }
    }
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:completion];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);
    
    UIMutableUserNotificationAction *action1;
    action1 = [[UIMutableUserNotificationAction alloc] init];
    [action1 setActivationMode:UIUserNotificationActivationModeBackground];
    [action1 setTitle:@"Accept"];
    [action1 setIdentifier:@"Accept"];
    [action1 setDestructive:NO];
    [action1 setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *action2;
    action2 = [[UIMutableUserNotificationAction alloc] init];
    [action2 setActivationMode:UIUserNotificationActivationModeBackground];
    [action2 setTitle:@"Decline"];
    [action2 setIdentifier:@"Decline"];
    [action2 setDestructive:NO];
    [action2 setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *actionCategory;
    actionCategory = [[UIMutableUserNotificationCategory alloc] init];
    [actionCategory setIdentifier:@"Actionable_notification"];
    [actionCategory setActions:@[action1, action2]
                    forContext:UIUserNotificationActionContextDefault];
    
    NSSet *categories = [NSSet setWithObject:actionCategory];
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                             categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = deviceToken;
    
    NSString *msg = [NSString stringWithFormat:@"didRegisterForRemoteNotificationsWithDeviceToken:%@",deviceToken];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showMsg" object:msg];
    NSLog(@"%@",msg);
    
    
    [self sendRequest:@"v1/user"
               method:@"POST"
                 body:@{@"uname": @"mcohen@line2.com",   //[UIDevice currentDevice].identifierForVendor.UUIDString,
                        @"dname": @"Mike",  //[UIDevice currentDevice].name,
                        @"device": [UIDevice currentDevice].model,
                        @"target": [deviceToken hexString],
                        @"timezone": @"America/Los Angeles",
                        @"type": @4
                        }
           completion:^(NSURLResponse *response, NSData *data, NSError *error) {
                     // handle completion or error
               if (response && data) {
                   // we got a response of some kind
                   NSError *jsonError = nil;
                   NSDictionary * result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                   NSString * userIdValue = [result objectForKey:@"id"];
                   NSString * ticketValue = [result objectForKey:@"ticket"];
                   
                   if (userIdValue != nil && ticketValue != nil) {
                       self.userid = [userIdValue integerValue];
                       self.ticket = ticketValue;
                       [self sendRequest:[NSString stringWithFormat:@"v1/user/%ld?ticket=%@",self.userid,self.ticket]
                                  method:@"PUT"
                                    body:@{@"code":@(123456)}
                              completion:^(NSURLResponse *response, NSData *data, NSError *error) {
                           // do something here
                                  NSLog(@"PUT completion: %@, error=%@",response,error);
                       }];
                   } else {
                       NSLog(@"POST request returned %@, result=%@",response,result);
                   }
               } else {
                   NSLog(@"Error: %@",error);
               }
                 }];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings {
    NSLog(@"didRegisterUserNotificationSettings:%@",settings);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification: (NSDictionary *)userInfo {
    NSLog(@"%@", userInfo);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notification" message:
                          [[userInfo objectForKey:@"aps"] valueForKey:@"alert"] delegate:nil cancelButtonTitle:
                          @"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError:%@",error);
}


@end
