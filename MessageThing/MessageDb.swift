//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import SQLite

struct Message {
  static let table = Table("message")
  static let textField = Expression<String?>("text")
  static let dateField = Expression<Int64>("date")

  let message: String?
  let date: Int64
}

class MessageDb {
  var dbPath: String
  var db: Connection

  init(dbPath: String = "/Users/petere/work/messages/chat.db") throws {
    self.dbPath = dbPath
    self.db = try Connection(dbPath)
  }

  func getUnreadTexts() throws -> [Message] {

    let q = Message.table
      .select(Message.textField, Message.dateField)
      .order(Message.dateField.desc)

    let iter = try db.prepareRowIterator(q)
    return try iter.map { msg in
      Message(message: msg[Message.textField],
              date: msg[Message.dateField])
    }
  }
}
