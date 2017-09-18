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
        
        broadcastConnection = UDPBroadcastConnection(port: Config.Ports.broadcast) { [unowned self] (ipAddress: String, port: Int, response: [UInt8]) -> Void in
            let log = "Received from \(ipAddress):\(port):\n\n\(response)"
            self.logView.text = log
        }
    }


    @IBAction func reload(_ sender: AnyObject) {
        self.logView.text = ""
        broadcastConnection.sendBroadcast(Config.Strings.broadcastMessage)
    }
    
}
