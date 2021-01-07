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
                handler: { [weak self] (ipAddress: String, port: Int, response: Data) -> Void in
                    guard let self = self else { return }
                    let hexString = self.hexBytes(data: response)
                    let utf8String = String(data: response, encoding: .utf8) ?? ""
                    print("UDP connection received from \(ipAddress):\(port):\n\(hexString)\n\(utf8String)\n")
                    self.log("Received from \(ipAddress):\(port):\n\(hexString)\n\(utf8String)\n")
                },
                errorHandler: { [weak self] (error) in
                    guard let self = self else { return }
					self.log(error: error)
            })
        } catch {
			if let connectionError = error as? UDPBroadcastConnection.ConnectionError {
				log(error: connectionError)
			}
			else {
				log("Error: \(error)\n")
			}
        }
    }
    
    private func hexBytes(data: Data) -> String {
        return data
            .map { String($0, radix: 16, uppercase: true) }
            .joined(separator: ", ")
    }
    
    
    @IBAction func reload(_ sender: AnyObject) {
        log("")
        do {
            try broadcastConnection.sendBroadcast(Config.Strings.broadcastMessage)
            log("Sent: '\(Config.Strings.broadcastMessage)'\n")
        } catch {
			if let connectionError = error as? UDPBroadcastConnection.ConnectionError {
				log(error: connectionError)
			}
			else {
				log("Error: \(error)\n")
			}
        }
    }
    
    private func log(_ message: String) {
        self.logView.text += message
    }

	private func log(error: UDPBroadcastConnection.ConnectionError) {
		switch error {
		case .sendingMessageFailed(code: let code):
			if let errorString = String(validatingUTF8: strerror(code)) {
				log("Error: sendingMessageFailed: \(errorString)\n")
			}
			else {
				log("Error: \(error)\n")
			}
		case .receiveFailed(code: let code):
			if let errorString = String(validatingUTF8: strerror(code)) {
				log("Error: receiveFailed: \(errorString)\n")
			}
			else {
				log("Error: \(error)\n")
			}
		case .reopeningSocketFailed(error: let socketError):
			log("Error: reopeningSocketFailed: \(socketError)\n")
		case .underlying(error: let underlying):
			log("Error: underlying: \(underlying)\n")
		default:
			log("Error: \(error)\n")
		}
	}
}
