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
    let METADATA = "swift example"
    let URL = "https://ortc-developers.realtime.co/server/2.1"
    var ortc: OrtcClient?
    
    func connect()
    {
        self.ortc = OrtcClient.ortcClientWithConfig(self)
        self.ortc!.connectionMetadata = METADATA
        self.ortc!.clusterUrl = URL
        self.ortc!.connect(APPKEY, authenticationToken: TOKEN)
    }
    
    func onConnected(ortc: OrtcClient){
        NSLog("CONNECTED")
        ortc.subscribe("SOME_CHANNEL", subscribeOnReconnected: true,
                       onMessage: { (ortcClient:OrtcClient!, chn:String!, m:String!) -> Void in
                        NSLog("Receive message: %@ on channel: %@", m!, chn!)
        })
    }
    
    func onDisconnected(ortc: OrtcClient){
        // Disconnected
    }
    
    func onSubscribed(ortc: OrtcClient, channel: String){
        // Subscribed to the channel
        
        // Send a message
        ortc.send(channel, message: "Hello world!!!")
    }
    
    func onUnsubscribed(ortc: OrtcClient, channel: String){
        // Unsubscribed from the channel 'channel'
    }
    
    func onException(ortc: OrtcClient, error: NSError){
        // Exception occurred
    }
    
    func onReconnecting(ortc: OrtcClient){
        // Reconnecting
    }
    
    func onReconnected(ortc: OrtcClient){
        // Reconnected
    }
}