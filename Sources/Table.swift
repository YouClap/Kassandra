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

private let connection = config.connection

/**
    Defines a Model Instance
 
     - Requirements
         - Field:            Associated Type for table Fields -> Use an Enum
         - tableName:        Name of the table being modelled
 
*/
public protocol Table {

    associatedtype Field: Hashable

    static var tableName: String { get }

}

public extension Table {
    typealias Document = [Field: Any]


    /**
        Creates a Select Query representing to count rows specified by the Table
        
        - Parameters:
            - fields:   Enum Fields representing tables fields to be counted

        Returns the Select Query
     
     */
    static func count(_ fields: Field...) -> Select {
        
        let fields = fields.map{ String(describing: $0) }

        var query = Select(fields, from: Self.tableName)

        query.sqlfunction = SQLFunction.count(fields)

        return query
    }


    /**
        Creates a Select Query representing for the given fields
     
        - Parameters:
            - fields:   Enum Fields representing tables fields to be selected
     
        Returns the Select Query
     
     */
    static func select(_ fields: Field ...) -> Select {
        return Select(fields.map{ String(describing: $0) }, from: Self.tableName)
    }
 

    /**
         Creates an Insert Query for the given Document
         
         - Parameters:
            - values:   [Field: Any] Document representing the key value pairs to be inserted
         
         Returns the Insert Query
     
     */
    static func insert(_ values: Document) -> Insert {
        return Insert(changeDictType(dict: values), into: Self.tableName)
    }
  
    
    /**
         Creates an Update Query for the given Document and Conditions
         
         - Parameters:
            - values:   [Field: Any] Document representing the updated key value pairs
            - conditions:  Predicate representing the Where condition
         
         Returns the Update Query
     
     */
    static func update(_ values: Document, conditions: Predicate) -> Update {
        
        let vals = changeDictType(dict: values)
        
        return Update(to: vals, in: Self.tableName, where: conditions)
    }
 
    /**
         Creates a Delete Query for the given condition
         
         - Parameters:
            - conditions:  Predicate representing the Where condition
         
         Returns the Delete Query
     
     */
    static func delete(where conditions: Predicate) -> Delete {
        
        return Delete(from: tableName, where: conditions)
    }

    /**
         Creates a Raw Query representing a Truncate table query

         Returns the Raw Query
     
     */
    static func truncate() -> Raw {
        return Raw(query: "TRUNCATE TABLE \(Self.tableName)")
    }


    /**
         Creates a Raw Query representing a Drop table query

         Returns the Raw Query
     
     */
    static func drop() -> Raw {
        return Raw(query: "DROP TABLE \(Self.tableName)")
    }
}
