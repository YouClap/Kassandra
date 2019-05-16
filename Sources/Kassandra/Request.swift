/**
 Copyright IBM Corporation 2017
 
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

public enum Request {
    
    // Startup Request Packet
    //
    //  Parameters:
    //      - Options: String dictionary containing startup options
    //
    // Returns a Ready Response
    case startup(options: [String: String])
    
    
    // Options Request Packet
    //
    // Returns a Supported Response denoting the startup options
    case options
    
    
    // Query Request Packet
    //
    //  Parameters:
    //      - using: Query Object to be executed
    //
    // Returns a Result Response
    case query(using: Query)
    
    
    // Prepare Request Packet
    //
    //  Parameters:
    //      - query: Query Object to be prepared
    //
    // Returns a Result Response
    case prepare(query: Query)
    
    
    // Exeucte Request Packet
    //
    //  Parameters:
    //      - query: Already Prepared Query Object to be Executed
    //
    //
    // Returns a Result Response
    case execute(query: Query)
    
    
    // Register Request Packet
    //
    //  Parameters:
    //      - events: [String] of events to register for
    //
    //
    // Returns a Result Response
    case register(events: [String])
    
    
    // Batch Request Packet
    //
    //  Parameters:
    //      - queries:      [Query] of prepared/unprepared queries to execute
    //      - type:         BatchType of the execution
    //      - flags:        Flags of the execution
    //      - consistency   Consistency for the execution
    //
    // Returns a Result Response
    case batch(queries: [Query], type: BatchType, flags: Byte, consistency: Consistency)
    
    
    // AuthResponse Request Packet
    //
    //  Parameters:
    //      - token: Int representing authorization token
    //
    //
    // Returns a AuthSucces or AuthChallenge Response
    case authResponse(with: Authenticator)


    public var opcode: Byte {
        switch self {
        case .startup        : return 0x01
        case .options        : return 0x05
        case .query          : return 0x07
        case .prepare        : return 0x09
        case .execute        : return 0x0A
        case .register       : return 0x0B
        case .batch          : return 0x0D
        case .authResponse   : return 0x0F
        }
    }
    
    internal func write(id: UInt16, writer: SocketWriter) throws {
        var body = Data()
        
        switch self {
        case .options                       : break
        case .query(let query)              : body.append(query.build().longStringData) ; body.append(query.packParameters())
        case .prepare(let query)            : body.append(query.build().longStringData)
        case .authResponse(let auth)        : body.append(auth.initialResponse().count.data) ; body.append(auth.initialResponse())
        case .execute(let query)            :
            
            if let id = query.preparedID {
                body.append(UInt16(id.count).data)
                body.append(Data(bytes: id, count: id.count))
                body.append(query.packParameters())
            } else {
                throw ErrorType.GenericError("Query does not have a prepared ID")
            }
            

        case .startup(let options)           :
            
            body.append(UInt16(options.count).data)
            
            for (key, value) in options {
                body.append(key.shortStringData)
                body.append(value.shortStringData)
            }
            
        case .register(let events)  :
            
            body.append(events.count.data)
            
            for event in events {
                body.append(event.shortStringData)
            }
            
        case .batch(let queries, let type, let flags, let consistency):

            body.append(type.rawValue.data)
            body.append(UInt16(queries.count).data)

            for query in queries {
                if let id = query.preparedID {
                    body.append(UInt8(0x01).data)
                    body.append(UInt16(id.count).data)
                    body.append(Data(bytes: id, count: id.count))
                } else {
                    body.append(UInt8(0x00).data)
                    body.append(query.build().longStringData)
                }
                
                body.append(UInt16(0).data)
            }

            body.append(consistency.rawValue.data)
            body.append(flags.data)
            
            if flags & 0x10 == 0x10 {
                body.append(Consistency.serial.rawValue.data)
            }

            if flags & 0x20 == 0x20 {
                body.append(Date.data)
            }
        }

        var header = Data()
        header.append(config._version.data)
        header.append(config.flags.data)
        header.append(id.bigEndian.data)
        header.append(opcode.data)

        header.append(body.count.data)
        header.append(body)

        try writer.write(from: header)
        
    }
}
