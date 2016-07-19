//
//  AppDelegate.swift
//  CloudKitDemo2
//
//  Created by JHJG on 2016. 7. 15..
//  Copyright © 2016년 KangJungu. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //애플리케이션이 실행되고 있지 않다면 알림창을 선택했을때 이 메서드가 호출되며 알림에 대한 정보가 이 메서드로 전달된다.
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //애플리케이션이 실행하고 알림을 받은것인지 묻는 알림창이 나온다.
        
        //알림이 수신되면 애플리케이션의 실행 아이콘에 배지를 표시하고 소리가 나도록 함.
        let settings = UIUserNotificationSettings(forTypes: [.Alert,.Badge,.Sound], categories: nil)
    
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        //애플리케이션이 실행되고 있지 않다면 알림창을 선택했을때 이 메서드가 호출되며 알림에 대한 정보가 이 메서드로 전달된다.
        //launchOptions 매개변수를 통해 전달된 데이터를 검증하면서 시작한다.
        if let options:NSDictionary = launchOptions{
            //키값이 반환된다면 그것을 didReceiveRemoteNotification 메서드에 전달한다.
            let remoteNotification = options.objectForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as? NSDictionary
            
            if let notification = remoteNotification{
                self.application(application,didReceiveRemoteNotification: notification as [NSObject : AnyObject])
                
            }
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //알림창을 선택했을때 애플리케이션이 포그라운드나 백그라운드에서 실행중이라면 이 메소드가 호출된다.
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        //최상의 뷰 컨트롤러의 객체를 얻는다.
        let viewController : ViewController = self.window?.rootViewController as! ViewController
        
        //메소드에 전달된 NSDictionary에서 CKNotification 객체를 추출한다.
        let notification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        //CKNotification 객체의 notificationType 속성을 검사하여 구독 결과로 실행된 알림임을 가리키는 CKNotificationType.Query인지 확인한다.
        if notification.notificationType == CKNotificationType.Query {
            let queryNotification = notification as! CKQueryNotification
            
            let recordID = queryNotification.recordID
            //레코드 아이디를 얻어서 뷰 컨트롤러의 fetchRecord에 전달한다.
            viewController.fetchRecord(recordID!)
        }
    }


}

