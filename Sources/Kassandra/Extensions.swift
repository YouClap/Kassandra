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

extension String: Convertible {

    var shortStringData: Data {
        var data = Data()

        if let utf = self.data(using: String.Encoding.utf8){
            data.append(UInt16(utf.count).data)
            data.append(utf)
        } else {
            data.append(UInt16(0).data)
        }

        return data
    }
    
    var longStringData: Data {   // long string
        var data = Data()

        if let utf = self.data(using: String.Encoding.utf8) {
            data.append(utf.count.data)
            data.append(utf)
        } else {
            data.append(0.data)
        }

        return data
    }
}

extension Int: Convertible {

    init(data: Data) {
        let u = Int(data[0]) << 24
        let um = Int(data[1]) << 16
        let lm = Int(data[2]) << 8
        let l = Int(data[3])
        
        self = u | um | lm | l
    }

    var data: Data {
        return Data(bytes: [UInt8((self & 0xFF000000) >> 24), UInt8((self & 0x00FF0000) >> 16),
                            UInt8((self & 0x0000FF00) >> 8), UInt8(self & 0x000000FF)], count: 4)
    }
}

extension UInt8: Convertible {

    var data: Data {
        return Data(bytes: [self])
    }
    
    var bool: Bool {
        return self == 0x01 ? true : false
    }
    
    var int: Int {
        return Int(self)
    }
}

extension UInt16: Convertible {
    
    static var random: UInt16 {
        #if os(Linux)
            return UInt16(rand() % Int32(UInt16.max))
        #else
            return UInt16(arc4random_uniform(UInt32(UInt16(max))))
        #endif
    }
    
    init(msb: UInt8, lsb: UInt8) {
        self = (UInt16(msb) << 8) | UInt16(lsb)
    }
    
    var data: Data {
        return Data(bytes: self.UInt8s, count: 2)
    }
    
    var UInt8s: [UInt8] {
        return [UInt8((self & 0xFF00) >> 8), UInt8(self & 0x00ff)]
    }
}
extension UUID: Convertible {}
extension Double: Convertible {}
extension Float: Convertible {}
extension UInt32 {
    var data: Data {
        return Data(bytes: [UInt8((self & 0xFF000000) >> 24), UInt8((self & 0x00FF0000) >> 16),
                            UInt8((self & 0x0000FF00) >> 8), UInt8(self & 0x000000FF)], count: 4)
    }
}
extension UInt64 {
    var data: Data {
        var data = UInt32((self & 0xFFFFFFFF00000000) >> 32).data
        data.append(UInt32((self & 0x00000000FFFFFFFF)).data)
        return data
    }
}
extension Date {
    static var data: Data {
        let stamp = Date().timeIntervalSince1970
        return stamp.bitPattern.data
    }
}
extension Data {

    mutating func subdata(with length: Int) -> Data {
        let blob = self.subdata(in: Range(0..<length))
        self = self.subdata(in: Range(length..<self.count))
        return blob
    }

    var decodeBlob: [UInt8] {
        mutating get {
            return self.filter{ _ in return true }
        }
    }
    
    var decodeShortBytes: [UInt8] {
        mutating get {
            return subdata(with: Int(self.decodeUInt16)).filter{ _ in return true }
        }
    }

    var decodeBool: Bool {
        mutating get {
            return self.decodeUInt8 == 0x0001 ? true : false
        }
    }

    var decodeUInt8: UInt8 {
        mutating get {
            let uint = UInt8(self[0])
            self = self.subdata(in: Range(1..<count))
            return uint
        }
    }

    var decodeUInt16: UInt16 {
        mutating get {
            let uint = UInt16(msb: self[0], lsb: self[1])
            self = self.subdata(in: Range(2..<self.count))
            return uint
        }
    }

    var decodeUInt32: UInt32 {
        mutating get {
            let u = UInt32(self.decodeUInt16) << 16
            let l = UInt32(self.decodeUInt16)
            
            return u | l
        }
    }
    
    var decodeUInt64: UInt64 {
        mutating get {
            let u = UInt64(self.decodeUInt32) << 32
            let l = UInt64(self.decodeUInt32)
            
            return u | l
        }
    }

    var decodeInt32: Int32 {
        mutating get {
            let u = Int32(self.decodeUInt16) << 16
            let l = Int32(self.decodeUInt16)
            
            return u | l
        }
    }

    var decodeInt: Int {
        mutating get {
            let u = Int(self.decodeUInt16) << 16
            let l = Int(self.decodeUInt16)

            return u | l
        }
    }

    var decodeBigInt: Int64 {
        mutating get {
            let u = Int64(self.decodeInt) << 32
            let l = Int64(self.decodeInt)

            return u | l
        }
    }

    var decodeDouble: Double {
        mutating get {
            let u = UInt64(self.decodeInt) << 32
            let l = UInt64(self.decodeInt)

            return Double(bitPattern: u | l)
        }
    }

    var decodeFloat: Float {
        mutating get {
            return Float(bitPattern: UInt32(self.decodeInt))
        }
    }
    
    var decodeDecimal: Decimal {
        mutating get {
            let scaled = UInt64(decodeUInt32)
            let unscaled = UInt64(decodeVarInt, radix: 16)!
            let test = Double(unscaled) * pow(10, (-1 * Double(scaled)))
            return Decimal(floatLiteral: test)
        }
    }
    
    var decodeVarInt: String {
        return toHex(data: self)
    }

    var decodeSString: String { // <Short String>
        mutating get {
            return subdata(with: Int(self.decodeUInt16)).decodeUTF8String
        }
    }

    var decodeLString: String { // <Long String>
        mutating get {
            return subdata(with: self.decodeInt).decodeUTF8String
        }
    }

    var decodeUTF8String: String {
        return String(data: self, encoding: String.Encoding.utf8) ?? "NULL"
    }

    var decodeAsciiString: String {
        return String(data: self, encoding: String.Encoding.ascii) ?? "NULL"
    }

    var decodeTimeStamp: Date {
        mutating get {
            let timeInterval = TimeInterval(exactly: Double(self.decodeUInt64 / UInt64(1000)))!
            return Date(timeIntervalSince1970: timeInterval)
        }
    }

    var decodeUUID: UUID {
        mutating get {
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            subdata(with: 16).copyBytes(to: data, count: 16)
            return UUID(uuidString: NSUUID(uuidBytes: data).uuidString)!
        }
    }
    
    var decodeTimeUUID: UUID {
        mutating get {
            return self.decodeUUID
        }
    }

    var decodeInet: (String, Int) {
        mutating get {
            if count == 4 {
                return ("\(String(describing: self[0])).\(String(describing: self[1])).\(String(describing: self[2])).\(String(describing: self[3]))", 0)
            } else {
                var result = ""
                for i in 0..<count {
                    result += toHex(data: Data(bytes: [self[i]], count:  1))
                    if i % 2 == 1 {
                        result += ":"
                    }
                }
                return (result, 0)
            }
        }
    }

    var decodeStringMap: [String: [String]] {
        mutating get {
            var map = [String: [String]]()
            
            for _ in 0..<Int(self.decodeUInt16) {

                let key = self.decodeSString

                var strList = [String]()

                for _ in 0..<Int(self.decodeUInt16) {
                    strList.append(self.decodeSString)
                }
                
                map[key] = strList
            }
            return map
        }
    }

    var decodeEventResponse: Result {
        mutating get {
            switch self.decodeSString {
            case "TOPOLOGY_CHANGE":
                return .event(of: .topologyChange(type: self.decodeSString, inet: self.decodeInet))
            case "STATUS_CHANGE":
                return .event(of: .statusChange(type: self.decodeSString, inet: self.decodeInet))
            case "SCHEMA_CHANGE":
                let changeType = self.decodeSString
                let target     = self.decodeSString
                
                 return target == "KeySpace" ?
                        .event(of: .schemaChange(type: changeType,
                                                target: target,
                                                changes:
                            .options(with: self.decodeSString)))
                :
                        .event(of: .schemaChange(type: changeType,
                                                target: target,
                                                changes:
                            .keyspace(to: self.decodeSString, withObjName: self.decodeSString)))
            default: return .event(of: .error(ErrorType.GenericError("Couldn't Parse Data")))
            }
        }
    }

    var decodePreparedResponse: Kind {
        mutating get {
            let id = self.decodeShortBytes

            let _ = self.decodeMetadata

            let _ = self.decodeMetadata

            return Kind.prepared(id: id)
        }
    }

    var decodeMetadata: Metadata {
        mutating get {
            let flags = self.decodeInt
            let columnCount = self.decodeInt
            var globalKeySpace: String? = nil
            var globalTableName: String? = nil
            var _ = Data() // paging state

            if flags & 0x0001 == 0x0001 {
                globalKeySpace = self.decodeSString
                globalTableName = self.decodeSString
            }

            if flags & 0x0002 == 0x0002 {
                let _ = self.subdata(with: self.decodeInt)
            }

            return flags & 0x0004 == 0x0004 ? Metadata(flags: flags) :
                Metadata(flags: flags, count: columnCount, keyspace: globalKeySpace, table: globalTableName, rowMetadata: nil)
        }
    }
    
    var decodeType: DataType? {
        mutating get {
            switch self.decodeUInt16 {
            case 0x0000: return DataType.custom
            case 0x0001: return DataType.ASCII
            case 0x0002: return DataType.bigInt
            case 0x0003: return DataType.blob
            case 0x0004: return DataType.boolean
            case 0x0005: return DataType.counter
            case 0x0006: return DataType.decimal
            case 0x0007: return DataType.double
            case 0x0008: return DataType.float
            case 0x0009: return DataType.int
            case 0x000A: return DataType.text
            case 0x000B: return DataType.timestamp
            case 0x000C: return DataType.uuid
            case 0x000D: return DataType.varChar
            case 0x000E: return DataType.varInt
            case 0x000F: return DataType.timeUUID
            case 0x0010: return DataType.inet
            case 0x0020: return DataType.list(type: self.decodeType!)
            case 0x0021: return DataType.map(keyType: self.decodeType!, valueType: self.decodeType!)
            case 0x0022: return DataType.set(type: self.decodeType!)
            case 0x0030:
                let keyspace = self.decodeSString
                let UDTname = self.decodeSString
                var headers = [Header]()
                for _ in 0..<self.decodeUInt16 {
                    headers.append(Header(field: self.decodeSString, type: self.decodeType!))
                }

                return DataType.UDT(keyspace: keyspace, name: UDTname,headers: headers)

            case 0x0031:
                var arr = [DataType]()
                for _ in 0..<Int(self.decodeUInt16) {
                    arr.append(self.decodeType!)
                }
                return DataType.tuple(types: arr)

            default: return nil
            }
        }
    }
    
    var decodeRows: Kind {
        mutating get {
            let metadata = self.decodeMetadata
            
            var headers = [Header]()
            var rowVals = [[Any]]()
            
            for _ in 0..<metadata.columnCount {
                if metadata.isRowHeaderPresent {
                    let _ = self.decodeSString //ksname
                    let _ = self.decodeSString //tablename
                }
                headers.append(Header(field: self.decodeSString, type: self.decodeType!))
            }
            
            // Parse Row Content
            for _ in 0..<self.decodeInt {
                
                var values = [Any]()
                
                for i in 0..<metadata.columnCount {
                    
                    guard case let length = Int(self.decodeInt32), length > 0 else {
                        values.append("NULL")
                        continue
                    }
                    
                    values.append(option(type: headers[i].type!,
                                         data: self.subdata(with: length)))
                }
                rowVals.append(values)
            }
            return .rows(rows: rowVals.map { dict(keys: headers, values: $0) })
        }
    }
}

public struct AnyKey: Hashable {
    public let underlying: Any
    public let hashValueFunc: () -> Int
    public let equalityFunc: (Any) -> Bool
    
    init<T: Hashable>(_ key: T) {
        underlying = key
        
        hashValueFunc = { key.hashValue }
        
        equalityFunc = {
            if let other = $0 as? T {
                return key == other
            }
            return false
        }
    }
    
    public var hashValue: Int { return hashValueFunc() }
}

public func ==(x: AnyKey, y: AnyKey) -> Bool {
    return x.equalityFunc(y.underlying)
}

private func option(type: DataType, data: Data) -> Any {
    var data = data
    
    switch type {
    case .custom            : return data.decodeUTF8String
    case .ASCII             : return data.decodeAsciiString
    case .bigInt            : return data.decodeBigInt
    case .blob              : return data.decodeBlob
    case .boolean           : return data.decodeBool
    case .counter           : return data.decodeInt
    case .decimal           : return data.decodeDecimal
    case .double            : return data.decodeDouble
    case .float             : return data.decodeFloat
    case .int               : return data.decodeInt
    case .text              : return data.decodeUTF8String
    case .timestamp         : return data.decodeTimeStamp
    case .uuid              : return data.decodeUUID
    case .varChar           : return data.decodeUTF8String
    case .varInt            : return data.decodeVarInt
    case .timeUUID          : return data.decodeUUID
    case .inet              : return data.decodeInet
    case .list(let type)    : return decodeList(type: type, data: data)
    case .map(let k, let v) : return decodeMap(keyType: k, valueType: v, data: data)
    case .set(let type)     : return decodeSet(type: type, data: data)
    case .tuple(let types)   : return decodeTuple(types: types, data: data)
    case .UDT(let key, let name, let headers):
        return (keyspace: key, name: name, decodeUDT(headers: headers, data: data))
    }
}

private func decodeList(type: DataType, data: Data) -> [Any] {

    var data = data
    var lst = [Any]()
    
    for _ in 0..<data.decodeInt {
        lst.append(option(type: type, data: data.subdata(with: data.decodeInt)))
    }

    return lst
}

private func decodeSet(type: DataType, data: Data) -> Set<AnyKey> {
    var data = data
    var lst = Set<AnyKey>()

    for _ in 0..<data.decodeInt {
        let val = option(type: type, data: data.subdata(with: data.decodeInt))
        
        if let key = AnyToKey(val) { lst.insert(key) }
        
    }

    return lst
}

private func decodeMap(keyType: DataType,valueType: DataType, data: Data) -> [AnyKey : Any] {

    var data = data
    var map = [AnyKey : Any]()
    
    for _ in 0..<data.decodeInt {
        
        let key   = option(type: keyType, data: data.subdata(with: data.decodeInt))
        let value = option(type: keyType, data: data.subdata(with: data.decodeInt))
        
        if let key = AnyToKey(key) { map[key] = value }
    }

    return map
}

private func decodeTuple(types: [DataType], data: Data) -> [Any] {

    var data = data
    var arr = [Any]()

    for type in types {
        arr.append(option(type: type, data: data.subdata(with: data.decodeInt)))
    }
    return arr
}

private func decodeUDT(headers: [Header], data: Data) -> [String: Any] {

    var data = data
    var obj = [String: Any]()
    
    for header in headers {
        obj[header.field] = option(type: header.type!, data: data.subdata(with: data.decodeInt))
    }
    return obj
}

public func AnyToKey(_ val: Any) -> AnyKey? {
    switch val {
    case let k as UInt64    : return AnyKey(k)
    case let k as Bool      : return AnyKey(k)
    case let k as Decimal   : return AnyKey(k)
    case let k as Double    : return AnyKey(k)
    case let k as Float     : return AnyKey(k)
    case let k as Int       : return AnyKey(k)
    case let k as String    : return AnyKey(k)
    case let k as Date      : return AnyKey(k)
    case let k as UUID    : return AnyKey(k)
    default: return nil
    }
}

private func toHex(data: Data) -> String {
    let buf = UnsafePointer<UInt8>(data.filter { _ in true })
    let charA = UInt8(UnicodeScalar("a").value)
    let char0 = UInt8(UnicodeScalar("0").value)
    
    func intToHex(value: UInt8) -> UInt8 {
        return (value > 9) ? (charA + value - 10) : (char0 + value)
    }
    
    let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count * 2)
    
    for i in 0 ..< data.count {
        ptr[i*2] = intToHex(value: (buf[i] >> 4) & 0xF)
        ptr[i*2+1] = intToHex(value: buf[i] & 0xF)
    }
    
    return String(bytesNoCopy: ptr, length: data.count*2, encoding: String.Encoding.utf8, freeWhenDone: true)!
}

public func dict(keys: [Header], values: [Any]) -> [String:Any] {
    precondition(keys.count == values.count)
    
    var ret = [String: Any]()
    
    for (index, key) in keys.enumerated() {
        ret[key.field] = values[index]
    }
    
    return ret
}

public func changeDictType<T>(dict: [T: Any]) -> [String: Any] {
    var cond = [String: Any]()
    
    for (key, value) in dict {
        cond[String(describing: key)] = value
    }
    
    return cond
}
public func changeDictType2<T,S>(dict: [T: S]) -> [String: S] {
    var cond = [String: S]()
    
    for (key, value) in dict {
        cond[String(describing: key)] = value
    }
    
    return cond
}
