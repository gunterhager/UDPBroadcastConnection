//
//  UDPBroadcastConnection.swift
//  UDPBroadcast
//
//  Created by Gunter Hager on 10.02.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation
import Darwin

// Addresses

let INADDR_ANY = in_addr(s_addr: 0)
let INADDR_BROADCAST = in_addr(s_addr: 0xffffffff)


/// An object representing the UDP broadcast connection. Uses a dispatch source to handle the incoming traffic on the UDP socket.
public class UDPBroadcastConnection {
    
    // MARK: Properties
    
    /// The address of the UDP socket.
    var address: sockaddr_in
    
    /// Closure that handles incoming UDP packets.
    var handler: ((ipAddress: String, port: Int, response: [UInt8]) -> Void)?
    
    /// A dispatch source for reading data from the UDP socket.
    var responseSource: dispatch_source_t?
    
    
    // MARK: Initializers
    
    /**
    Initializes the UDP connection with the correct port address. Note: this doesn't open a socket! The socket is opened transparently as needed when sending broadcast messages.
    
    - parameter port: Number of the UDP port to use.
    
    - returns: Returns an initialized UDP broadcast connection.
    */
    public init(port: UInt16, handler: ((ipAddress: String, port: Int, response: [UInt8]) -> Void)?) {
        self.address = sockaddr_in(
            sin_len:    __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port:   UDPBroadcastConnection.htonsPort(port),
            sin_addr:   INADDR_BROADCAST,
            sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
        )
        
        self.handler = handler
    }
    
    deinit {
        if responseSource != nil {
            dispatch_source_cancel(responseSource!)
        }
    }
    
    // MARK: Interface
    
    
    /**
    Create a UDP socket for broadcasting and set up cancel and event handlers
    
    - returns: Returns true if the socket was created successfully.
    */
    private func createSocket() -> Bool {
        
        // Create new socket
        let newSocket: Int32 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard newSocket > 0 else { return false }
        
        // Enable broadcast on socket
        var broadcastEnable = Int32(1);
        let ret = setsockopt(newSocket, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(sizeof(UInt32)));
        if ret == -1 {
            print("Couldn't enable broadcast on socket")
            close(newSocket)
            return false
        }
        
        // Disable global SIGPIPE handler so that the app doesn't crash
        setNoSigPipe(newSocket)
        
        // Set up a dispatch source
        let newResponseSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(newSocket), 0, dispatch_get_main_queue())
        
        // Set up cancel handler
        dispatch_source_set_cancel_handler(newResponseSource) {
            print("Closing UDP socket")
            let UDPSocket = Int32(dispatch_source_get_handle(newResponseSource))
            shutdown(UDPSocket, SHUT_RDWR)
            close(UDPSocket)
        }
        
        // Set up event handler (gets called when data arrives at the UDP socket)
        dispatch_source_set_event_handler(newResponseSource) { [unowned self] in
            guard let source = self.responseSource else { return }
            
            var socketAddress = sockaddr_storage()
            var socketAddressLength = socklen_t(sizeof(sockaddr_storage.self))
            let response = [UInt8](count: 4096, repeatedValue: 0)
            let UDPSocket = Int32(dispatch_source_get_handle(source))
            
            let bytesRead = withUnsafeMutablePointer(&socketAddress) {
                recvfrom(UDPSocket, UnsafeMutablePointer<Void>(response), response.count, 0, UnsafeMutablePointer($0), &socketAddressLength)
            }
            
            guard bytesRead >= 0 else {
                if let errorString = String(UTF8String: strerror(errno)) {
                    print("recvfrom failed: \(errorString)")
                }
                self.closeConnection()
                return
            }
            
            guard bytesRead > 0 else {
                print("recvfrom returned EOF")
                self.closeConnection()
                return
            }
            
            guard let endpoint = withUnsafePointer(&socketAddress, { self.getEndpointFromSocketAddress(UnsafePointer($0)) }) else {
                print("Failed to get the address and port from the socket address received from recvfrom")
                self.closeConnection()
                return
            }
            
            print("UDP connection received \(bytesRead) bytes from \(endpoint.host):\(endpoint.port)")
            
            // Handle response
            self.handler?(ipAddress: endpoint.host, port: endpoint.port, response: response)
        }
        
        dispatch_resume(newResponseSource)
        responseSource = newResponseSource
        
        return true
    }
    
    /**
    Send broadcast message.
    
    - parameter message: Message to send via broadcast.
    */
    public func sendBroadcast(message: String) {
        
        if responseSource == nil {
            guard createSocket() else {
                print("UDP ServerConnection initialization failed.")
                return
            }
        }
        
        guard let source = responseSource else { return }
        let UDPSocket = Int32(dispatch_source_get_handle(source))
        message.withCString { broadcastMessage in
            let broadcastMessageLength = Int(strlen(broadcastMessage) + 1) // We need to include the 0 byte to terminate the C-String
            let sent = withUnsafePointer(&address) {
                sendto(UDPSocket, broadcastMessage, broadcastMessageLength, 0, UnsafePointer($0), socklen_t(address.sin_len))
            }
            
            guard sent > 0 else {
                if let errorString = String(UTF8String: strerror(errno)) {
                    print("UDP connection failed to send data: \(errorString)")
                }
                closeConnection()
                return
            }
            
            if sent == broadcastMessageLength {
                // Success
                print("UDP connection sent \(broadcastMessageLength) bytes")
            }
        }
    }
    
    /**
    Close the connection.
    */
    public func closeConnection() {
        if let source = responseSource {
            dispatch_source_cancel(source)
            responseSource = nil
        }
    }
    
    // MARK: - Helper
    
    /**
    Convert a sockaddr structure into an IP address string and port.
    
    - parameter socketAddressPointer: Pointer to a socket address.
    
    - returns: Returns a tuple of the host IP address and the port in the socket address given.
    */
    func getEndpointFromSocketAddress(socketAddressPointer: UnsafePointer<sockaddr>) -> (host: String, port: Int)? {
        let socketAddress = UnsafePointer<sockaddr>(socketAddressPointer).memory
        
        switch Int32(socketAddress.sa_family) {
        case AF_INET:
            var socketAddressInet = UnsafePointer<sockaddr_in>(socketAddressPointer).memory
            let length = Int(INET_ADDRSTRLEN) + 2
            var buffer = [CChar](count: length, repeatedValue: 0)
            let hostCString = inet_ntop(AF_INET, &socketAddressInet.sin_addr, &buffer, socklen_t(length))
            let port = Int(UInt16(socketAddressInet.sin_port).byteSwapped)
            return (String.fromCString(hostCString)!, port)
            
        case AF_INET6:
            var socketAddressInet6 = UnsafePointer<sockaddr_in6>(socketAddressPointer).memory
            let length = Int(INET6_ADDRSTRLEN) + 2
            var buffer = [CChar](count: length, repeatedValue: 0)
            let hostCString = inet_ntop(AF_INET6, &socketAddressInet6.sin6_addr, &buffer, socklen_t(length))
            let port = Int(UInt16(socketAddressInet6.sin6_port).byteSwapped)
            return (String.fromCString(hostCString)!, port)
            
        default:
            return nil
        }
    }

    
    // MARK: - Private
    
    private func setNoSigPipe(socket: CInt) {
        // prevents crashes when blocking calls are pending and the app is paused ( via Home button )
        var no_sig_pipe: Int32 = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)));
    }
    
    private class func htonsPort(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
    
    private class func ntohs(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }
    
}




