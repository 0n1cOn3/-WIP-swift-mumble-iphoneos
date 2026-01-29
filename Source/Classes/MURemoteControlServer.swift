// Copyright 2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation
import Darwin

/// Remote control server for PTT commands.
/// Listens on TCP port 54295 for remote push-to-talk control.
@objc(MURemoteControlServer)
@objcMembers
class MURemoteControlServer: NSObject {

    // MARK: - Constants

    private static let port: UInt16 = 54295

    // MARK: - Singleton

    @objc static let shared = MURemoteControlServer()

    @objc class func sharedRemoteControlServer() -> MURemoteControlServer {
        return shared
    }

    // MARK: - Private Properties

    private var activeSocks: [Int32] = []
    private var socket: CFSocket?
    private var socketContext: CFSocketContext?
    private let lock = NSLock()

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Socket Management

    fileprivate func addSocket(_ sock: Int32) {
        lock.lock()
        activeSocks.append(sock)
        lock.unlock()
    }

    fileprivate func removeSocket(_ sock: Int32) {
        lock.lock()
        if let index = activeSocks.firstIndex(of: sock) {
            activeSocks.remove(at: index)
        }
        lock.unlock()
    }

    private func closeAllSockets() {
        lock.lock()
        for sock in activeSocks {
            close(sock)
        }
        activeSocks.removeAll()
        lock.unlock()
    }

    // MARK: - Server Control

    /// Check if the server is running.
    @objc var isRunning: Bool {
        return socket != nil
    }

    /// Start the remote control server.
    @objc func start() -> Bool {
        // Create socket context with self reference
        var context = CFSocketContext(
            version: 0,
            info: Unmanaged.passRetained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        // Create the socket
        socket = CFSocketCreate(
            nil,
            PF_INET6,
            SOCK_STREAM,
            IPPROTO_TCP,
            CFSocketCallBackType.acceptCallBack.rawValue,
            { (socket, callbackType, address, data, info) in
                MURemoteControlServer.acceptCallback(socket: socket, callbackType: callbackType, address: address, data: data, info: info)
            },
            &context
        )

        guard let sock = socket else {
            return false
        }

        // Set socket options
        var val: Int32 = 1
        setsockopt(CFSocketGetNative(sock), SOL_SOCKET, SO_REUSEADDR, &val, socklen_t(MemoryLayout<Int32>.size))

        // Bind to address
        var addr6 = sockaddr_in6()
        memset(&addr6, 0, MemoryLayout<sockaddr_in6>.size)
        addr6.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        addr6.sin6_family = sa_family_t(AF_INET6)
        addr6.sin6_port = MURemoteControlServer.port.bigEndian
        addr6.sin6_flowinfo = 0
        addr6.sin6_addr = in6addr_any

        let addressData = withUnsafePointer(to: &addr6) { ptr in
            Data(bytes: ptr, count: MemoryLayout<sockaddr_in6>.size)
        }

        let err = CFSocketSetAddress(sock, addressData as CFData)
        if err != .success {
            CFSocketInvalidate(sock)
            socket = nil
            return false
        }

        // Add to run loop
        let source = CFSocketCreateRunLoopSource(nil, sock, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)

        return true
    }

    /// Stop the remote control server.
    @objc func stop() -> Bool {
        closeAllSockets()

        if let sock = socket {
            CFSocketInvalidate(sock)
            socket = nil
        }

        return true
    }

    // MARK: - Accept Callback

    private static func acceptCallback(socket: CFSocket?, callbackType: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, info: UnsafeMutableRawPointer?) {
        guard let info = info else { return }
        guard callbackType == .acceptCallBack else { return }
        guard let data = data else { return }

        let server = Unmanaged<MURemoteControlServer>.fromOpaque(info).takeUnretainedValue()
        let clientSocket = data.assumingMemoryBound(to: Int32.self).pointee

        server.addSocket(clientSocket)

        // Start client handler thread
        Thread.detachNewThread {
            server.handleClient(clientSocket)
        }
    }

    // MARK: - Client Handler

    private func handleClient(_ sock: Int32) {
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.removeSocket(sock)
            }
            close(sock)
        }

        // Set SO_NOSIGPIPE to prevent SIGPIPE on write to closed socket
        var val: Int32 = 1
        if setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &val, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            return
        }

        var action: UInt8 = 0

        while true {
            let nread = read(sock, &action, 1)

            if nread == 0 {
                // Connection closed
                return
            }

            if nread == -1 {
                NSLog("MURemoteControlServer: aborted server thread: %s", String(cString: strerror(errno)))
                return
            }

            let on = (action & 0x1) != 0
            let code = action & ~0x1

            if code == 0 {
                // PTT command
                DispatchQueue.main.async {
                    let audio = MKAudio.sharedAudio()
                    let captureManager = MUAudioCaptureManager.shared

                    if on {
                        captureManager.beginPushToTalk()
                    } else {
                        captureManager.endPushToTalk()
                    }

                    audio?.forceTransmit = on
                }
            }
        }
    }
}
