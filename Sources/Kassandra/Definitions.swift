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

public typealias Byte = UInt8

// Return Error codes
//
public enum ErrorType: Error {
    case ReadError
    case WriteError
    case SerializeError
    case ConnectionError
    case NoDataError
    case GenericError(String)
    case IOError
    case CassandraError(Int, String)
}

// Cassandra 3 Supported Compression Types
//
public enum CompressionType: String {
    case lz4        = "LZ4Compressor"
    case snappy     = "SnappyCompressor"
    case deflate    = "DeflateCompressor"
    case none       = ""
    
}


// Keyspace Replication Strategies
//
public enum ReplicationStrategy: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .simple( let factor )         : return "REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : \(factor) }"
        case .networkTopology(let centers) : return "REPLICATION = { 'class' : 'NetworkTopologyStrategy'[\(centers.map {key, value in  "'\(key)' : \(value)"}.joined(separator: ", "))] }"
        }
    }
    case simple(numberOfReplicas: Int)
    case networkTopology(centers: [String: Int])
}

// Cassandra Supported Consistency Levels
//
public enum Consistency: UInt16 {
    case any = 0x00
    case one = 0x01
    case two = 0x02
    case three = 0x03
    case quorum = 0x04
    case all = 0x05
    case local_quorum = 0x06
    case each_quorum = 0x07
    case serial = 0x0008
    case local_serial = 0x0009
    case local_one = 0x000A
    case unknown
}

// Cassandra Supported DataTypes
//
public indirect enum DataType {
    
    case custom
    case ASCII
    case bigInt
    case blob
    case boolean
    case counter
    case decimal
    case double
    case float
    case int
    case text
    case timestamp
    case uuid
    case varChar
    case varInt
    case timeUUID
    case inet
    case list(type: DataType)
    case map(keyType: DataType, valueType: DataType)
    case set(type: DataType)
    case UDT(keyspace: String, name: String, headers: [Header])
    case tuple(types: [DataType])
    
    public var opcode: UInt16 {
        switch self {
        case .custom    : return 0x0000
        case .ASCII     : return 0x0001
        case .bigInt    : return 0x0002
        case .blob      : return 0x0003
        case .boolean   : return 0x0004
        case .counter   : return 0x0005
        case .decimal   : return 0x0006
        case .double    : return 0x0007
        case .float     : return 0x0008
        case .int       : return 0x0009
        case .text      : return 0x000A
        case .timestamp : return 0x000B
        case .uuid      : return 0x000C
        case .varChar   : return 0x000D
        case .varInt    : return 0x000E
        case .timeUUID  : return 0x000F
        case .inet      : return 0x0010
        case .list      : return 0x0020
        case .map       : return 0x0021
        case .set       : return 0x0022
        case .UDT       : return 0x0030
        case .tuple     : return 0x0031
        }
    }
}

//  Types of Batch Execution Type
//
public enum BatchType: Byte {
    case logged     = 0x00
    case unlogged   = 0x01
    case counter    = 0x02
}

//  Flags for Query
//
public enum Flags: Byte {
    case none = 0x00
    case compression = 0x01
    case tracing = 0x02
    case all = 0x03
    
}

public enum QueryFlags {
    case values
    case skipMetadata
    case pageSize(Int)
    case withPagingState
    case withSerialConsistency
    case withTimestamp
    case withValueNames
}

public enum SQLFunction<T> {
    case max([T])
    case min([T])
    case avg([T])
    case sum([T])
    case count([T])
    
    func pack() -> String {
        switch self {
        case .max(let args)     : return args.count == 0 ? "MAX(*)" : "MAX(\(args.map{ String(describing: $0) }.joined(separator: ", ")))"
        case .min(let args)     : return args.count == 0 ? "MIN(*)" : "MIN(\(args.map{ String(describing: $0) }.joined(separator: ", ")))"
        case .avg(let args)     : return args.count == 0 ? "AVG(*)" : "AVG(\(args.map{ String(describing: $0) }.joined(separator: ", ")))"
        case .sum(let args)     : return args.count == 0 ? "SUM(*)" : "SUM(\(args.map{ String(describing: $0) }.joined(separator: ", ")))"
        case .count(let args)   : return args.count == 0 ? "COUNT(*)" : "COUNT(\(args.map{ String(describing: $0) }.joined(separator: ", ")))"
        }
    }
}


internal struct Metadata {
    let flags: Int
    let columnCount: Int
    let keyspace: String?
    let table: String?
    let rowMetadata: [CqlColMetadata]?
    
    var isRowHeaderPresent: Bool {
        return flags & 0x0001 == 0x0001 ? false : true
    }
    
    var hasPagination: Bool {
        return flags & 0x0002 == 0x0002 ? false : true
    }
    
    init(flags: Int, count: Int = 0, keyspace: String? = nil, table: String? = nil, rowMetadata: [CqlColMetadata]? = nil){
        self.flags = flags
        self.columnCount = count
        self.keyspace = keyspace
        self.table = table
        self.rowMetadata = rowMetadata
    }
}

internal enum ResponseOpcodes: UInt8 {
    case error          = 0x00
    case ready          = 0x02
    case authenticate   = 0x03
    case supported      = 0x06
    case result         = 0x08
    case authSuccess    = 0x10
    case event          = 0x0C
    case authChallenge  = 0x0E
}

internal struct CqlColMetadata {
    public var keyspace: String
    public var table: String
    public var col_name: String
    public var col_type: String
    public var col_type_aux1: String
    public var col_type_aux2: String
}

internal func packType(_ item: Any) -> String {
    switch item {
    case let val as [Any]           : return String(describing: val.map { packType($0) } )
    case let val as [String: Any]   : return "{ \(val.map { key, value in "\(packType(key)) : \(packType(value))" }.joined(separator: ", ")) }"
    case let val as String          : return "'\(val)'"
    case let val as Date            : return String(describing: UInt64(val.timeIntervalSince1970) * 1000)
    case let val as UUID            : return String(describing: val.uuidString)
    default                         : return String(describing: item)
    }
}

internal func packColumnData(key: String, columns: [String: DataType]) -> String {
    
    var str = ""
    for (name, type) in columns {
        switch type {
        case .custom    : str += name + " custom "
        case .ASCII     : str += name + " ASCII "
        case .bigInt    : str += name + " bigInt "
        case .blob      : str += name + " blob "
        case .boolean   : str += name + " boolean "
        case .counter   : str += name + " counter "
        case .decimal   : str += name + " decimal "
        case .double    : str += name + " double "
        case .float     : str += name + " float "
        case .int       : str += name + " int "
        case .text      : str += name + " text "
        case .timestamp : str += name + " timestamp "
        case .uuid      : str += name + " uuid "
        case .varChar   : str += name + " text "
        case .varInt    : str += name + " varInt "
        case .timeUUID  : str += name + " timeUUID "
        case .inet      : str += name + " inet "
        case .list      : str += name + " list "
        case .map       : str += name + " map "
        case .set       : str += name + " set "
        case .UDT       : str += name + " UDT "
        case .tuple     : str += name + " tuple "
        }
        
        name == key ? (str += "PRIMARY KEY,") : (str += ",")
    }
    return str
}

internal func packPairs(_ pairs: [String: Any], mirror: Mirror? = nil) -> String {
    return pairs.map{key,val in  key + "=" + packType(val) }.joined(separator: ", ")
}

internal func packKeys(_ dict: [String: Any]) -> String {
    return dict.map {key, value in key }.joined(separator: ", ")
}

internal func packKeys(_ mirror: Mirror) -> String {
    return mirror.children.map { $0.label! }.joined(separator: ", ")
}

internal func packValues(_ dict: [String: Any]) -> String {
    return dict.map {key, value in packType(value) }.joined(separator: ", ")
}

internal func packValues(_ mirror: Mirror) -> String {
    return mirror.children.map{ packType($0.value) }.joined(separator: ", ")
}
