//
//  OrtcClient.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 18/04/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import RealtimeMessaging_iOS_Swift

class OrtcClass: NSObject, OrtcClientDelegate{
    
    let APPKEY = "uzgkbk"
    let TOKEN = "56c602ba44dee5412f2ca6e3adc692"
    //http://198.211.98.86/queue:\(session[0].id!)
    //let TOKEN = "TWkS6JoEW4wa"
    let METADATA = "Iphone Device"
    let URL = "https://ortc-developers.realtime.co/server/2.1"
    var ortc: OrtcClient?
    var session = [Session]()
    
    func connect()
    {
        self.ortc = OrtcClient.ortcClientWithConfig(self)
        self.ortc!.connectionMetadata = METADATA
        self.ortc!.clusterUrl = URL
        self.ortc!.connect(APPKEY, authenticationToken: TOKEN)
    }
    
    func onConnected(ortc: OrtcClient){
        
        session = SessionDAO.fetchSession()

        NSLog("CONNECTED")
        ortc.subscribe("http://198.211.98.86/queue:\(session[0].id!)", subscribeOnReconnected: true) { (ortc, channel, message) in
            print(message)
            print(channel)
        }
    }
    
    func onDisconnected(ortc: OrtcClient){
        // Disconnected
        print("Disconnected")
    }
    
    func onSubscribed(ortc: OrtcClient, channel: String){
        // Subscribed to the channel
        print("subscribed to channel: \(channel)")
        ortc.send("http://198.211.98.86/queue:\(session[0].id!)", message: "DINKAO")
    }
    
    func onUnsubscribed(ortc: OrtcClient, channel: String){
        // Unsubscribed from the channel 'channel'
        print("unsubscribed channel")
    }
    
    func onException(ortc: OrtcClient, error: NSError){
        // Exception occurred
        print(error)
    }
    
    func onReconnecting(ortc: OrtcClient){
        // Reconnecting
    }
    
    func onReconnected(ortc: OrtcClient){
        // Reconnected
    }
}