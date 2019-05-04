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

import Foundation

public enum Result: CustomStringConvertible {


    // Error Result
    //
    case error(Error)


    // Ready Response due to Connect
    //
    case ready


    // Response received on startup denoting the type of authentication required
    //
    case authenticate(with: String)


    // Supported Response denonting startup options
    //
    case supported(by: [String: [String]])

    
    // Result Response of Kind type
    // - Kinds: - void      - keyspace      - schema
    //          - rows      - prepared
    //
    case result(of: Kind)


    // Response received on authentication success
    //
    case authSuccess


    // Response Denotes an Event Notification
    //
    case event(of: Event)


    // Response received from a Auth_Response request
    //  - A server authentication challenge
    //
    case authChallenge(with: Int)
    
    
 
    /** Convenience Variables to Retreive Data  */
    
    public var success: Bool {
        switch self {
        case .error : return false
        default     : return true
        }
    }
    
    public var asError: Error? {
        switch self {
        case .error(let err) : return err
        default              : return nil
        }
    }
    
    public var asRows: [Row]? {
        switch self {
        case .result(let kind) :
            switch kind {
            case .rows(let rows) : return rows
            default                 : return nil
            }
        default: return nil
        }
    }
 
    public var asOptions: [String: [String]]? {
        switch self {
        case .supported(let dict) : return dict
        default: return nil
        }
    }

    public var asPrepared: [Byte]? {
        switch self {
        case .result(let kind) :
            switch kind {
            case .prepared(let id) : return id
            default                      : return nil
            }
        default: return nil
        }
    }
    
    public var asKeyspace: String? {
        switch self {
        case .result(let kind) :
            switch kind {
            case .keyspace(let name)     : return name
            default                      : return nil
            }
        default: return nil
        }
    }
    
    public var asSchema: (type: String, target: String, options: String)? {
        switch self {
        case .result(let kind) :
            switch kind {
            case .schema(let t, let s, let o)  : return (type: t, target: s, options: o)
            default                            : return nil
            }
        default: return nil
        }
    }
    
    public var description: String {
        switch self {
        case .error (let error)             : return "Error: \(error)"
        case .ready                         : return "Ready"
        case .authenticate(let authType)    : return "Authenticate Type: \(authType)"
        case .supported(let map)            : return "Supports: \(map)"
        case .result(let kind)              : return kind.description
        case .authSuccess                   : return "Authentication Success"
        case .event(let type)               : return type.description
        case .authChallenge(let token)      : return "Authentication Challenge Token: \(token)"
        }
    }
    
    internal init(opcode: UInt8, body: Data) {
        var body = body
        
        let opcode = ResponseOpcodes(rawValue: opcode)!
        
        switch opcode {
        case .ready         : self = .ready
        case .authSuccess   : self = .authSuccess
        case .supported     : self = .supported(by: body.decodeStringMap)
        case .result        : self = .result(of: Kind(body: body))
        case .authChallenge : self = .authChallenge(with: body.decodeInt)
        case .authenticate  : self = .authenticate(with: body.decodeSString)
        case .error         : self = .error(ErrorType.CassandraError(body.decodeInt, body.decodeSString))
        case .event         : self = body.decodeEventResponse
        }
    }
}
