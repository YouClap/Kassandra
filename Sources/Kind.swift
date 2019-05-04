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

/**
    Result of a Query Request
 
    - Void      : Successful Operation
    - Rows      : Result of a Select Query Containing [String: Any] Dictionary
    - Schema    : Result of a Schema Change Denoting Type of Change, Table Target, Options
    - Keyspace  : Result of a Keyspace change Denoting the in-use keyspace
    - Prepared  : Result of a Prepared Query Containing its [Bytes] ID
 
 */
public enum Kind {
    
    public var description: String {
        switch self {
        case .void                           : return "Void"
        case .rows                           : return "Rows"
        case .schema(let t, let ta, let o)   : return "Scheme type: \(t), target: \(ta), options: \(o)"
        case .keyspace(let name)             : return "KeySpace: \(name)"
        case .prepared                       : return "Prepared"
        }
    }

    internal init(body: Data) {
        var body = body
        
        let type = body.decodeInt

        switch type {
        case 2 : self = body.decodeRows
        case 3 : self = .keyspace(name: body.decodeSString)
        case 4 : self = body.decodePreparedResponse
        case 5 : self = .schema(type: body.decodeSString, target: body.decodeSString, options: body.decodeSString)
        default: self = .void
        }
    }

    case void

    case rows(rows: [Row])

    case schema(type: String, target: String, options: String)

    case keyspace(name: String)

    case prepared(id: [Byte])

}


public struct Header: Hashable, Equatable {
    let field: String
    let type: DataType?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(field)
        hasher.combine(type?.opcode ?? 1)
    }

    public static func ==(lhs: Header, rhs: Header) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}


