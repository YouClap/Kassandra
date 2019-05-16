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
 import Socket
 import SSLService
 import Dispatch

 public class KassandraClient {

     public var delegate: KassandraDelegate? = nil

     internal var socket: Socket?

     internal var readQueue: DispatchQueue
     internal var writeQueue: DispatchQueue

     internal var buffer: Data

     internal var map = [UInt16: (Result) -> Void]()


     /**
          Initializes a Kassandra Instance

          - Parameters
             - host:             String denoting the server host - defaults to localhost
             - port:             Int32 denoting the server port  - defaults to 9042
             - authentication:   Username/Password tuple denoting user to connect with
             - cqlVersion:       String representation of vql version to use (supported: >3.0.0)
             - connect:          Whether to automatically connect or not

          Returns a QueryResult Enum through the callback

      */
     public init(host: String = "localhost",
                 port: Int32 = 9042,
                 using authentication: (username: String, password: String)? = nil,
                 cqlVersion: String = "3.2.0") {

         config.setHostAndPort(host: host, port: port)
         config.setCQLVersion(cqlVersion: cqlVersion)

         if let auth = authentication {
             config.setAuth(PlainText(username: auth.username, password: auth.password))
         }

         socket = nil

         buffer = Data()

         readQueue = DispatchQueue(label: "read queue", attributes: DispatchQueue.Attributes.concurrent)
         writeQueue = DispatchQueue(label: "write queue", attributes: DispatchQueue.Attributes.concurrent)

     }

     /**
          Connects to a Kassandra Server

          - Parameters
             - keyspace      : Optional keyspace to automatically conenct to
             - compression   : Compression Type to use
             - onCompletion  : Callback function for on completion

          Returns a Result through the given callback

      */
     public func connect(with keyspace: String? = nil,
                         compression: CompressionType = .none,
                         oncompletion: @escaping (Result) -> Void) throws {

         if socket == nil {
             socket = try! Socket.create(family: .inet6, type: .stream, proto: .tcp)
         }

         guard let sock = socket else {
             throw ErrorType.GenericError("Could not create a socket")

         }

         do {
             config.compression = compression

             try sock.connect(to: config.host, port: config.port)

             let id = UInt16.random

                 self.map[id] =  { result in

                     if let space = keyspace {
                         result.success ? self.execute("USE \(space)", oncompletion: oncompletion) : oncompletion(Result.error(ErrorType.ConnectionError))
                     } else {
                         oncompletion(result)
                     }
                 }

             try Request.startup(options: config.options).write(id: id, writer: sock)

             config.connection = self

         } catch {
             oncompletion(Result.error(ErrorType.ConnectionError))
             return
         }

         read()

     }

     /**
         Authenticate your cassandra instance using a username/password

             ** Works with Cassandra PasswordAuthenticator

          - Parameters
              - username      : Username for Cassandra Database
              - password      : Password for Cassandra Database
              - onCompletion  : Callback function for on completion

         Result will either be an authSuccess on success or an authChallenge
     */
     public func authenticate(username: String, password: String, oncompletion: @escaping ((Result) -> Void)) {
         authenticate(with: PlainText(username: username, password: password), oncompletion: oncompletion)
     }

     internal func authenticate(with auth: Authenticator, oncompletion: @escaping ((Result) -> Void)) {
         executeHandler(.authResponse(with: auth), oncompletion: oncompletion)
     }

     /**
         Executes a Create Index Query

         - Parameters
             - table         : Name of the table to place index on
             - field         : Name of the field to place index on
             - onCompletion  : Callback function for on completion

         Returns a Result Enum through the given callback

     */
     public func create(in table: String, on field: String, oncompletion: @escaping ((Result) -> Void)) {
         self.execute("CREATE INDEX ON \(table)(\(field))", oncompletion: oncompletion)
     }

     /**
         Executes a Create Keyspace Query

          - Parameters
             - keyspace      : Name of the keyspace to create
             - strategy      : Type of Replication Strategy to Use
             - isDurable     : Optional parameter for `Durable_Writes,` defaults to true
             - ifNotExists   : Optional parameter to add "IF NOT EXISTS"
             - onCompletion  : Callback function for on completion

          Returns a Result Enum through the given callback
      */
     public func create(keyspace: String, with strategy: ReplicationStrategy, isDurable: Bool = true, ifNotExists: Bool = false, oncompletion: @escaping ((Result) -> Void)) {
         self.execute("CREATE KEYSPACE \(ifNotExists ? "IF NOT EXISTS" : "") \(keyspace) WITH \(strategy) AND DURABLE_WRITES = \(isDurable);", oncompletion: oncompletion)
     }

     /**
          Executes a String Representation of a CSQL Query

          - Parameters
             - query:        String Representation of a CSQL Query to be executed
             - onCompletion: Callback function for on completion

          Returns a Result Enum through the given callback
      */
     public func execute(_ query: String, oncompletion: @escaping ((Result) -> Void)) {
         let request = Request.query(using: Raw(query: query))
         executeHandler(request, oncompletion: oncompletion)
     }


     /**
          Executes a String Representation of a CSQL Query

          - Parameters
             - query:        String Representation of a CSQL Query to be executed
             - onCompletion: Callback function for on completion

          Returns a Result Enum through the given callback
      */
     public func execute(_ request: Request, oncompletion: @escaping ((Result) -> Void)) {
         executeHandler(request, oncompletion: oncompletion)
     }


     /**
          Executes a String Representation of a CSQL Query

          - Parameters
             - query:        String Representation of a CSQL Query to be executed
             - onCompletion: Callback function for on completion

          Returns a Result Enum through the given callback
      */
     public func execute(_ query: Query, oncompletion: @escaping ((Result) -> Void)) {
         executeHandler(.query(using: query), oncompletion: oncompletion)
     }

     private func executeHandler(_ request: Request, oncompletion: @escaping ((Result) -> Void)) {
         guard let sock = socket else {
             oncompletion(Result.error(ErrorType.GenericError("Socket Not Connected")))
             return
         }
         writeQueue.async {
             do {

                 let id = UInt16.random

                 self.map[id] = oncompletion

                 try request.write(id: id, writer: sock)

             } catch {
                 oncompletion(.error(ErrorType.ConnectionError))
             }
         }
     }
 }

 extension KassandraClient {

     /**
          Initialize a configuration using a `CA Certificate` directory.

          *Note:* `caCertificateDirPath` - All certificates in the specified directory **must** be hashed using the `OpenSSL Certificate Tool`.

          - Parameters:
              - caCertificateDirPath:        Path to a directory containing CA certificates. *(see note above)*
              - certificateFilePath:        Path to the PEM formatted certificate file. If nil, `certificateFilePath` will be used.
              - keyFilePath:                Path to the PEM formatted key file (optional). If nil, `certificateFilePath` is used.
              - selfSigned:                True if certs are `self-signed`, false otherwise. Defaults to true.

      */

     public func setSSL(certPath: String? = nil, keyPath: String? = nil) throws {

         let SSLConfig = SSLService.Configuration(withCACertificateDirectory: nil, usingCertificateFile: certPath, withKeyFile: keyPath)

         try setSSL(SSLConfig)
     }

     /**
          Initialize a configuration using a `Certificate Chain File`.

          *Note:* If using a certificate chain file, the certificates must be in PEM format and must be sorted starting with the subject's certificate (actual client or server certificate), followed by intermediate CA certificates if applicable, and ending at the highest level (root) CA.

          - Parameters:
              - chainFilePath:            Path to the certificate chain file (optional). *(see note above)*
              - selfSigned:                True if certs are `self-signed`, false otherwise. Defaults to true.

      */
     public func setSSL(with ChainFilePath: String, usingSelfSignedCert: Bool) throws {

         let SSLConfig = SSLService.Configuration(withChainFilePath: ChainFilePath, usingSelfSignedCerts: usingSelfSignedCert)

         try setSSL(SSLConfig)
     }

     /**
          Initialize a configuration using a `CA Certificate` file.

          - Parameters:
              - caCertificateFilePath:    Path to the PEM formatted CA certificate file.
              - certificateFilePath:        Path to the PEM formatted certificate file.
              - keyFilePath:                Path to the PEM formatted key file. If nil, `certificateFilePath` will be used.
              - selfSigned:                True if certs are `self-signed`, false otherwise. Defaults to true.

      */
     public func setSSL(with CACertificatePath: String?, using CertificateFile: String?, with KeyFile: String?, selfSignedCerts: Bool) throws {

         let SSLConfig = SSLService.Configuration(withCACertificateFilePath: CACertificatePath,
                                                  usingCertificateFile: CertificateFile,
                                                  withKeyFile: KeyFile,
                                                  usingSelfSignedCerts: selfSignedCerts)
         try setSSL(SSLConfig)
     }

     private func setSSL(_ SSLConfig: SSLService.Configuration) throws {

         config.SSLConfig = SSLConfig

         socket?.delegate = try SSLService(usingConfiguration: SSLConfig)
     }
 }

 extension KassandraClient {

     internal func read() {

         guard let sock = socket else {
             return
         }

         let iochannel = DispatchIO(type: DispatchIO.StreamType.stream, fileDescriptor: sock.socketfd, queue: readQueue, cleanupHandler: {
             error in
         })

         iochannel.read(offset: off_t(0), length: 1, queue: readQueue) {
             done, data, error in

             let bytes: [Byte]? = data?.map {
                 byte in
                 return byte
             }

             if let d = bytes {

                 self.buffer.append(d, count: d.count)

                 if self.buffer.count >= 9 {
                     self.unpack()
                 }

                 self.read()
             }
         }
     }

     private func unpack() {
         while buffer.count >= 9 {

             //Unpack header
             let flags       = UInt8(buffer[1])
             let streamID    = UInt16(msb: buffer[3], lsb: buffer[2])
             let opcode      = UInt8(buffer[4])
             let bodyLength  = Int(data: buffer.subdata(in: Range(5...8)))

             // Do we have all the bytes we need for the full packet?
             let bytesNeeded = buffer.count - bodyLength - 9

             if bytesNeeded < 0 {
                 return
             }

            let body = buffer.subdata(in: 9..<9 + bodyLength)

             buffer = buffer.subdata(in: 9 + bodyLength..<buffer.count)

             handle(id: streamID, flags: flags, Result(opcode: opcode, body: body))

         }
     }

     private func handle(id: UInt16, flags: Byte, _ response: Result) {
         switch response {
         case .event(let event)       : delegate?.didReceiveEvent(event: event)
         case .authenticate(_)        :

             guard let auth = config.auth, let onCompletion = map[id] else {
                 map[id]?(response)
                 return
             }

             self.authenticate(with: auth, oncompletion: onCompletion)

         case .authChallenge(_)      : break
         default                     : map[id]?(response)
         }
     }
 }

 // Custom operators for database
 extension KassandraClient {
     subscript(_ database: String) -> Bool {
         do {
             let request = Raw(query: "USE \(database);")

             let r = Request.query(using: request)

             if let s = socket {
                 try r.write(id: 0, writer: s)
             }

         } catch {
             return false
         }
         return true
     }

 }
