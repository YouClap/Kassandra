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

public protocol Authenticator {
    func initialResponse() -> Data
    func evaluateChallenge()
}

/**
    A Struct Authenticator that works with Cassandra's PasswordAuthenticator.
 
    - Parameters:
        - username: Username used to connect to cassandra
        - password: Password used to connect to cassandra
 */
public struct PlainText: Authenticator {
    let username: String
    let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public func initialResponse() -> Data {
        var body = Data()
        
        guard let user = username.data(using: String.Encoding.utf8),
              let pass = password.data(using: String.Encoding.utf8) else {
                
                return body
        }

        body.append(0x00)
        body.append(user)
        body.append(0x00)
        body.append(pass)

        return body
    }
    
    public func evaluateChallenge() {
        return
    }
}
