/**
 Copyright IBM Corporation 2016
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Socket
import Foundation

public class Server {

    private var socket: Socket?
    
    public var host: String = "localhost"
    public var port: Int32 = 9042
    
    private var readQueue: DispatchQueue
    private var writeQueue: DispatchQueue
    
    init(host: String, port: Int32) {
        self.host = host
        self.port = port
        socket = nil
        readQueue = DispatchQueue(label: "read queue", attributes: .concurrent)
        writeQueue = DispatchQueue(label: "write queue", attributes: .concurrent)
        
    }
    
    public func connect() throws {
        
        if socket == nil {
            socket = try! Socket.create(family: .inet6, type: .stream, proto: .tcp)
        }
        
        guard let sock = socket else {
            throw RCErrorType.GenericError("Could not create a socket")
            
        }
        
        do {
            try sock.connect(to: host, port: port)
            
            try Request.startup(options: [:]).write(id: 0, writer: sock)
            
        } catch {
            return
        }
        
        //read()
        
    }
}