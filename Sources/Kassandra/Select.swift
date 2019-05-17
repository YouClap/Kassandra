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

public struct Select: Query {
    
    let table: String
    
    let fields: [String]
    
    var orderBy: String? = nil
    
    var conditions: Predicate? = nil
    
    var limitResultCount: Int? = nil
    
    var distinct = false
    
    var having : Having?
    
    var sqlfunction: SQLFunction<String>? = nil
    
    var consistency: Consistency
    
    var flags: Flags = .none
    
    public var preparedID: [Byte]? = nil
    
    public init(_ fields: [String], from table: String, consistency: Consistency = .one) {
        self.fields = fields
        self.table = table
        self.consistency = consistency
    }
    
    public func order(by clause: Order...) -> Select {
        var new = self
        new.ordered(by: clause)
        return new
    }
    
    public func having(_ clause: Having) -> Select {
        var new = self
        new.has(clause)
        return new
    }
    
    public func limit(to newLimit: Int?) -> Select {
        var new = self
        new.limited(to: newLimit)
        return new
    }
    
    public func filter(by conditions: Predicate?) -> Select {
        var new = self
        new.filtered(by: conditions)
        return new
    }
    
    public func with(consistency: Consistency = .any, flags: Flags = .none) -> Select {
        var new = self
        new.set(consistency: consistency, flags: flags)
        return new
    }
    
    private mutating func ordered(by clause: [Order]) {
        orderBy = clause.map { $0.description }.joined(separator: ", ")
    }
    
    private mutating func has(_ clause: Having) {
        having = clause
    }
    
    private mutating func limited(to newLimit: Int?) {
        limitResultCount = newLimit
    }
    
    private mutating func filtered(by conditions: Predicate?) {
        self.conditions = conditions
    }
    
    private mutating func set(consistency: Consistency = .any, flags: Flags = .none) {
        self.flags = flags
        self.consistency = consistency
    }

    public func build() -> String {
        var result = distinct ? "SELECT DISTINCT" : "SELECT "
        
        if let function = sqlfunction?.pack() {
            fields.count == 0 ? (result += "\(function) FROM \(table)") :
                (result += "\(function), \(fields.joined(separator: " ")) FROM \(table)")
        } else {
            fields.count == 0 ? (result += "* FROM \(table)") :
                (result += "\(fields.joined(separator: " ")) FROM \(table)")
        }
        
        if let cond = conditions {
            result += " WHERE " + cond.str
        }
        if let order = orderBy {
            result += " ORDER BY \(order)"
        }
        if let havingClause = having {
            result += " HAVING \(havingClause.clause)"
        }
        if let limit = limitResultCount {
            result += " LIMIT \(limit)"
        }

        return (result + ";")
    }
    
    public func packParameters() -> Data {
        var data = Data()
        
        data.append(consistency.rawValue.data)
        data.append(flags.rawValue.data)
        
        return data
    }
}
