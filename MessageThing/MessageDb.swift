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
  static let attributedBodyField = Expression<NSAttributedString?>("attributedBody")

  let message: String?
  let date: Int64
  let attributedBody: NSAttributedString?
}

class MessageDb {
  var dbPath: String
  var db: Connection
  var lastDateRead: Int64 = 0

  init(dbPath: String = "/Users/petere/work/messages/chat.db") throws {
    self.dbPath = dbPath
    self.db = try Connection(dbPath)
  }

  func getUnreadTexts() throws -> [Message] {

    let query = Message.table
//      .select(Message.textField, Message.dateField)
      .where((Message.dateField > lastDateRead) && (Message.isFromMe == 0))
      .order(Message.dateField.asc)

    let iter = try db.prepareRowIterator(query)

    let messages = try iter.map { msg in
      Message(message: msg[Message.textField],
              date: msg[Message.dateField],
              attributedBody: msg[Message.attributedBodyField])
    }

    if messages.isEmpty {
      return []
    }

    if let lastdate = messages.last?.date {
      lastDateRead = lastdate
    }
    
    return messages
  }
}
