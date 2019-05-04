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

import SSLService

public var config = Config.sharedInstance

public final class Config {
    
    var host: String = "localhost"
    
    var port: Int32 = 9042
    
    var cqlVersion: String = "3.2.0"

    let _version: Byte = 0x03

    var connection: Kassandra? = nil

    var SSLConfig: SSLService.Configuration? = nil

    var flags: Byte = 0x00

    var _compression: CompressionType = .none

    var auth: Authenticator? = nil

    // Connection Options
    //
    public var options: [String: String] {
        var opts = [String: String]()
        opts["CQL_VERSION"]  = cqlVersion

        if compression != .none {
            opts["COMPRESSION"] = compression.rawValue
        }
        return opts
    }

    // Versioning number of Cassandra
    //
    public var version: Int {
        return Int(_version)
    }

    // Getter and Setter for compression type to use
    //
    public var compression: CompressionType {
        get {
            return _compression
        }
        set {
            _compression = newValue
            newValue != .none ? flags = flags | 0x01 : ()
        }
    }
    
    // Getter and Setter for tracing option
    //
    public var tracing: Bool  {
        get {
            return (flags & 0x02) == 0x02 ? true : false
        }
        set {
            flags = flags | 0x02
        }
    }

    // Method to set cassandra's host and port
    //
    public func setHostAndPort(host: String, port: Int32){
        self.host = host
        self.port = port
    }
    
    // Method to set cassandra's CQL version
    //
    public func setCQLVersion(cqlVersion: String) {
        self.cqlVersion = cqlVersion
    }

    // Method to set cassandra's Authenticator
    //
    public func setAuth(_ auth: Authenticator?) {
        self.auth = auth
    }
    internal static var sharedInstance = Config()
    
    private init(){}
}
