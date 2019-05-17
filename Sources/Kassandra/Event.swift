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
     Event Result
     
     - Topological Change    : Denotes events related to change in the cluster topology
     - Status Change         : Denotes events related to change of node status          
     - Schema Change         : Denotes events related to schema change
     
 */
public enum Event: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .topologyChange(let type, let inet) :
            return "Topology Change with Type: \(type) and Inet \(inet)"
        case .statusChange(let type, let inet)   :
            return "Status Change with Type: \(type) and Inet \(inet)"
        case .schemaChange(let type, let target, let changes):
            return "Schema Change: Type - \(type), Target - \(target): Changes: \(changes)"
        case .error(let err):
            return "\(err)"
        }
    }
    
    case topologyChange(type: String, inet: (String, Int))
    
    case statusChange(type: String, inet: (String, Int))
    
    case schemaChange(type: String, target: String, changes: SchemaChange)
    
    case error(Error)
}

/**
    Event Schema Change Result
 
    - options   : Represents thekeyspace changed
    - keyspace  : Keyspace containing the affected object, and the name of the affected object

 */
public enum SchemaChange: CustomStringConvertible {
    
    public var description: String {
        switch self{
        case .options(let options): return "\(options)"
        case .keyspace(let name, let objName): return "\(name) \(objName)"
            
        }
    }
    
    case options(with: String)
    
    case keyspace(to: String, withObjName: String)
}
