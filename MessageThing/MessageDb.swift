//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import SQLite

extension NSAttributedString: Value {
  public class var declaredDatatype: String {
      return Blob.declaredDatatype
  }
  
  public class func fromDatatypeValue(_ blobValue: Blob) -> NSAttributedString {
    let data = Data.fromDatatypeValue(blobValue)
    do {
      return try NSAttributedString(data: data, options: [:],
                                    documentAttributes: nil)
    }
    catch {
      return NSAttributedString()
    }
  }

  public var datatypeValue: Blob {
    return Blob(bytes: []) // Don't care ATM
  }
}

struct Message {
  static let table = Table("message")
  static let textField = Expression<String?>("text")
  static let dateField = Expression<Int64>("date")
  static let isFromMe = Expression<Int>("is_from_me")
  static let attributedBodyField = Expression<Data?>("attributedBody")

  let message: String?
  let date: Int64
}

class MessageDb {
  var dbPath: String
  var db: Connection
  var lastMessageDate: Int64 = 0
  
  init(dbPath: String = "/Users/petere/Library/Messages/chat.db") throws {
    self.dbPath = dbPath
    self.db = try Connection(dbPath, readonly: true)
  }
  
  func unarchive(data: Data?) -> String? {
    guard let data = data else {
      return nil
    }

    if let obj = NSUnarchiver.unarchiveObject(with: data) {
      if let str = obj as? NSAttributedString {
        return str.string
      }
    }
    
    return nil
  }

  func getUnreadMessages() throws -> [Message] {

    let query = Message.table
      .select(Message.textField, Message.dateField, Message.attributedBodyField)
      .where((Message.dateField > lastMessageDate) && (Message.isFromMe == 0))
      .order(Message.dateField.asc)

    let iter = try db.prepareRowIterator(query)

    let messages = try iter.map { msg in
      let text = unarchive(data: msg[Message.attributedBodyField]) ?? msg[Message.textField]
      return Message(message: text, date: msg[Message.dateField])
    }

    if !messages.isEmpty {
      if let lastdate = messages.last?.date {
        self.lastMessageDate = lastdate
      }
    }
    
    return messages
  }
}
