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

public protocol Convertible {
    
}

public enum Order {
    case ascending(Convertible)
    case descending(Convertible)
    
    var description: String {
        switch self {
        case .ascending(let field ) : return "\(field) ASCD"
        case .descending(let field ) : return "\(field) DESC"
        }
    }
}

public struct Having: Convertible {
    var clause: String
    
    public init(_ clause: String) {
        self.clause = clause
    }
}

public func == (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) == \(String(describing: rhs))")
}
public func != (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) != \(String(describing: rhs))")
}
public func > (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) > \(String(describing: rhs))")
}
public func >= (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) >= \(String(describing: rhs))")
}
public func < (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) < \(String(describing: rhs))")
}
public func <= (lhs: String, rhs: Convertible) -> Having {
    return Having("\(lhs) <= \(String(describing: rhs))")
}

public func && (lhs: Having, rhs: Having) -> Having {
    return Having("\(lhs.clause), \(rhs.clause)")
}
public func || (lhs: Having, rhs: Having) -> Having {
    return Having("\(lhs.clause), \(rhs.clause)")
}

public enum WhereConvertible {
    case notEqual(String, Convertible)
    case equal(String, Convertible)
    case greaterThan(String, Convertible)
    case greaterThanOrEqual(String, Convertible)
    case lessThan(String, Convertible)
    case lessThanOrEqual(String, Convertible)
    case and(Predicate, Predicate)
    case or(Predicate, Predicate)
    case inOp(String, [Convertible])
}

public struct Predicate: Convertible  {
    let str: String
    
    init(_ expession: WhereConvertible) {
        switch expession {
        case .notEqual(let lhs, let rhs)             : str = "\(lhs) != \(packType((rhs)))"
        case .equal(let lhs, let rhs)                : str = "\(lhs) = \(packType(rhs))"
        case .greaterThan(let lhs, let rhs)          : str = "\(lhs) > \(packType(rhs))"
        case .greaterThanOrEqual(let lhs, let rhs)   : str = "\(lhs) >= \(packType(rhs))"
        case .lessThan(let lhs, let rhs)             : str = "\(lhs) < \(packType(rhs))"
        case .lessThanOrEqual(let lhs, let rhs)      : str = "\(lhs) <= \(packType(rhs))"
        case .and(let lhs, let rhs)                  : str = "\(lhs.str) AND \(rhs.str)"
        case .or(let lhs, let rhs)                   : str = "\(lhs.str) OR \(rhs.str)"
        case .inOp(let lhs, let rhs)                 : str = "\(lhs) IN (\(rhs.map { packType($0) }.joined(separator: ", ")))"
        }
    }
}

public func ==(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.equal(key, predicate))
}

public func !=(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.notEqual(key, predicate))
}

public func >(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.greaterThan(key, predicate))
}

public func >=(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.greaterThanOrEqual(key, predicate))
}

public func <(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.lessThan(key, predicate))
}

public func <=(key: String, predicate: Convertible) -> Predicate {
    return Predicate(.lessThanOrEqual(key, predicate))
}

public func &&(rhs: Predicate, lhs: Predicate) -> Predicate {
    return Predicate(.and(rhs, lhs))
}

public func ||(rhs: Predicate, lhs: Predicate) -> Predicate {
    return Predicate(.or(rhs, lhs))
}

/**
precedencegroup ComparisonPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecendence
}

infix operator > : ComparisonPrecedence
*/
public func > (lhs: String, rhs: [Convertible]) -> Predicate {
    return Predicate(.inOp(lhs, rhs))
}

