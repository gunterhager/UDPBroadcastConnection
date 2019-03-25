//
//  ViewController.swift
//  UDPBroadcastExample
//
//  Created by Gunter Hager on 10.02.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import UIKit
import UDPBroadcast

class ViewController: UIViewController {
    
    @IBOutlet var logView: UITextView!
    
    var broadcastConnection: UDPBroadcastConnection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logView.text = "UDP Broadcast: tap on reload button to start sending.\n\n"
        
        do {
            broadcastConnection = try UDPBroadcastConnection(
                port: Config.Ports.broadcast,
                handler: { [weak self] (ipAddress: String, port: Int, response: [UInt8]) -> Void in
                    guard let self = self else { return }
                    self.log("Received from \(ipAddress):\(port):\n\n\(response)\n")
                },
                errorHandler: { [weak self] (error) in
                    guard let self = self else { return }
                    self.log("Error: \(error)\n")
            })
        } catch {
            log("Error: \(error)\n")
        }
    }
    
    
    @IBAction func reload(_ sender: AnyObject) {
        log("")
        do {
            try broadcastConnection.sendBroadcast(Config.Strings.broadcastMessage)
            log("Sent: '\(Config.Strings.broadcastMessage)'\n")
        } catch {
            log("Error: \(error)\n")
        }
    }
    
    private func log(_ message: String) {
        self.logView.text += message
    }
    
}
