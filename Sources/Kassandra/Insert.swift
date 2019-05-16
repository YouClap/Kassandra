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

public struct Insert: Query {
    
    let tableName: String
    
    let fields: [String: Any]
    
    var consistency: Consistency
    
    var flags: Flags = .none
    
    public var preparedID: [Byte]? = nil
    
    public init(_ fields: [String: Any], into tableName: String, consistency: Consistency = .any) {
        self.fields = fields
        self.tableName = tableName
        self.consistency = consistency
    }
    
    public mutating func set(consistency: Consistency = .any, flags: Flags = .none) {
        self.flags = flags
        self.consistency = consistency
    }
    
    public func with(consistency: Consistency = .any, flags: Flags = .none) -> Insert {
        var new = self
        new.set(consistency: consistency, flags: flags)
        return new
    }
    
    public func build() -> String {
        let keys = packKeys(fields)
        let vals = packValues(fields)
        
        return ("INSERT INTO \(tableName) (\(keys)) VALUES(\(vals));")
    }
    
    public func packParameters() -> Data {
        var data = Data()
        
        data.append(consistency.rawValue.data)
        data.append(flags.rawValue.data)
        
        return data
    }
}
