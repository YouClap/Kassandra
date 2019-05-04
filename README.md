# 🚧 This project is being updated to Swift 5 and new versions of Cassandra

We are working on a new version of this driver using SwiftNIO.

# Kassandra

A pure Swift client library for [Apache Cassandra (3.4+)](http://cassandra.apache.org/) and [ScyllaDB](http://www.scylladb.com/) using Cassandra's binary protocol, CQL 3.2.

![](https://img.shields.io/badge/Swift-5.0%20Release-orange.svg?style=flat)
![](https://img.shields.io/badge/platform-Linux,%20macOS-blue.svg?style=flat)

## Installation

```swift
.package(url: "https://github.com/youclap/Kassandra.git", from: "1.0.1")
```

## Basic usage

### Prepare your queries

You must first connect to the database before you can execute SQL statements. You can specify the keyspace to use in the connect statement.

```swift
let kassandra = Kassandra()
try kassandra.connect(with: "mykeyspace") { error in 
    kassandra.execute("SELECT * FROM bread;")

}
```

## Create a Model

In order to persist objects, they must conform to the `Model` protocol.

```swift
struct Post {
    var id: UUID?
    let user: String
    let body: String
    let timestamp: Date
}
```

The model specifies the table name to use, the primary key that is used, and the fieldTypes.

```swift
extension Post: Model {
    enum Field: String {
        case id = "id"
        case user = "user"
        case body  = "message"
        case timestamp = "timestamp"
    }
    
    static let tableName = "Posts"
    
    static var primaryKey: Field {
        return Field.id
    }
    
    static var fieldTypes: [Field: DataType] {
        return [
            .id         : .uuid,
            .user       : .text,
            .body       : .text,
            .timestamp  : .timestamp
        ]
    }
    
    var key: UUID? {
        get {
            return self.id
        }
        set {
            self.id = newValue
        }
    }
    
    init(row: Row) {
        self.id         = row["id"] as? UUID
        self.user       = row["user"] as! String
        self.body       = row["body"] as! String
        self.timestamp  = row["timestamp"] as! Date
    }
}
```

### Save an object

Persisting an object with Kassandra is easy, and only requires the save method.

```swift

let post = Post(id: UUID(), user: user, body: message, timestamp: Date())

post.save()

```

---

## Detailed Installation 

1. Install OpenSSL:

    - macOS:
    ```
    $ brew install openssl
    ```
    - Linux:
    ```
    $ sudo apt-get install openssl
    ```

2. Add `Kassandra` to your `Package.swift`

    ```swift
    import PackageDescription

    let package = Package(
    	dependencies: [
		.Package(url: "https://github.com/IBM-Swift/Kassandra.git", majorVersion: 1)
    	]
    )
    ```

3. Create XCode project to build library (Optional)

    ```
    $ swift package generate-xcodeproj \
            -Xswiftc -I/usr/local/opt/openssl/include \
            -Xlinker -L/usr/local/opt/openssl/lib
    ```

4. In Sources/main.swift, import the Kassandra module.

    ``` Swift
    import Kassandra
    ```
5. Build Locally

	- macOS
	```
	$ swift build -Xcc -I/usr/local/opt/openssl/include -Xlinker -L/usr/local/opt/openssl/lib
	```
	- Linux
	```
	$ swift build -Xcc -I/usr/local/opt/openssl/include -Xlinker -L/usr/local/opt/openssl/lib
	```

## License 

Copyright 2017 IBM

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
