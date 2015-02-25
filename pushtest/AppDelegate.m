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

- (void)registerWithToken:(NSString*)token name:(NSString*)name;
- (void)showMsg:(NSString*)msg;

@end

@implementation AppDelegate

static const NSString * base_url = @"http://7f03b67ca2c84eec8ba0c3d550e74b99.cloudapp.net/";

- (void)showMsg:(NSString*)msg {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showMsg" object:msg];
    NSLog(@"%@",msg);
}

- (void)registerWithToken:(NSString*)token name:(NSString*)name {
    [self sendRequest:@"v1/user"
               method:@"POST"
                 body:@{@"uname":name,   //[UIDevice currentDevice].identifierForVendor.UUIDString,
                        @"dname": @"Mike",  //[UIDevice currentDevice].name,
                        @"device": [UIDevice currentDevice].model,
                        @"target": token,
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
                                  [self showMsg:[NSString stringWithFormat:@"PUT completion: %@, error=%@",response,error]];
                              }];
                   } else {
                       [self showMsg:[NSString stringWithFormat: @"POST request returned %@, result=%@",response,result]];
                   }
               } else {
                   [self showMsg:[NSString stringWithFormat:@"Error: %@",error]];
               }
           }];
    
}


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
    [action1 setActivationMode:UIUserNotificationActivationModeForeground];
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
    [actionCategory setActions:@[action1, action2] forContext:UIUserNotificationActionContextDefault];
    [actionCategory setActions:@[action1,action2] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories = [NSSet setWithObject:actionCategory];
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                             categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
//    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

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
    
    [self showMsg: [NSString stringWithFormat:@"didRegisterForRemoteNotificationsWithDeviceToken:%@",deviceToken] ];
    [self registerWithToken:[deviceToken hexString] name: @"4154168477"];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings {
    NSLog(@"didRegisterUserNotificationSettings:%@",settings);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification: (NSDictionary *)userInfo {
    [self showMsg:[NSString stringWithFormat:@"%@", userInfo]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Remote Notification" message:
                          [[userInfo objectForKey:@"aps"] valueForKey:@"alert"] delegate:nil cancelButtonTitle:
                          @"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self showMsg:[NSString stringWithFormat:@"%@", notification.userInfo]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Local Notification"
                                                    message:notification.alertBody
                                                   delegate:nil
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier
                                                       forLocalNotification:(UILocalNotification *)notification
                                                          completionHandler:(void (^)())completionHandler {
    
    NSString *msg = [NSString stringWithFormat:@"received action %@",identifier];
    [self showMsg:msg];
 
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];

    if (nil != completionHandler) {
        completionHandler();
    }
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self showMsg:[NSString stringWithFormat:@"didFailToRegisterForRemoteNotificationsWithError:%@",error]];
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    
    [self showMsg:[NSString stringWithFormat:@"didInvalidatePushTokenForType %@",type]];
    
}

-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    
    [self showMsg:[NSString stringWithFormat:@"didReceiveIncomingPushWithPayload: %@", payload.dictionaryPayload]];
    
    UILocalNotification *note = [[UILocalNotification alloc] init];
    note.soundName = UILocalNotificationDefaultSoundName;
    note.alertBody = [NSString stringWithFormat:@"Received VOIP push with payload: %@",payload.dictionaryPayload];
    note.category = @"Actionable_notification";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:note];
    
}

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    if([credentials.token length] == 0) {
        [self showMsg:[NSString stringWithFormat:@"voip token NULL"]];
        
        return;
    }
    
    [self showMsg:[NSString stringWithFormat:@"didUpdatePushCredentials: %@ - Type: %@", credentials.token, type]];
    
    [self registerWithToken:[credentials.token hexString] name: @"4154168478"];
    
}


@end
