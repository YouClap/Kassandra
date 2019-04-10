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

public protocol Query {
    
    var preparedID: [Byte]? { get set }
    
    func build() -> String
    func packParameters() -> Data
}

extension Query {

    /**
         Convienence Function to prepare queries
         
         Parameters:
            - oncompletion: Callback Closure
         
         Returns a Result type through the given callback
     */
    public func prepare(oncompletion: @escaping ((Result)->Void)) {
        config.connection?.execute(.prepare(query: self), oncompletion: oncompletion)
    }


    /**
         Convienence Function to execute non-prepared queries
         
         Parameters:
            - oncompletion: Callback Closure
         
         Returns a Result type through the given callback
     */
    public func execute(oncompletion: @escaping ((Result)->Void)) {
        config.connection?.execute(.query(using: self), oncompletion: oncompletion)
    }
}

/**
     Convienence Function to excute batch queries from arrays
     
     Parameters:
     - type:         Batch Type of the operation
     - consis:       Consistency for the operation
     - oncompletion: Callback Closure
     
     Returns a Result type through the given callback
 */
extension Array where Element: Query {
    
    public func execute(with type: BatchType, consis: Consistency, oncompletion: @escaping ((Result)->Void)) {
        let request: Request = Request.batch(queries: self, type: type, flags: 0x00, consistency: .any)
        config.connection?.execute(request, oncompletion: oncompletion)
    }
}

