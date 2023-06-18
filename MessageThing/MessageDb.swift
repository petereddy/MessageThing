//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import SQLite

//extension NSAttributedString: Value {
//  public class var declaredDatatype: String {
//      return Blob.declaredDatatype
//  }
//  public class func fromDatatypeValue(_ blobValue: Blob) -> NSAttributedString {
//    let data = NSKeyedUnarchiver(forReadingFrom: blobValue.bytes)
//    return NSAttributedString()
////      return UIImage(data: Data.fromDatatypeValue(blobValue))!
//  }
//  public var datatypeValue: Blob {
//    NSAttributedString *fancyText = [NSKeyedUnarchiver unarchiveObjectWithData:data];
////      return UIImagePNGRepresentation(self)!.datatypeValue
//  }
//}

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
  var lastDateRead: Int64 = 0

  init(dbPath: String = "/Users/petere/work/messages/chat.db") throws {
    self.dbPath = dbPath
    self.db = try Connection(dbPath)
  }

  func getUnreadTexts() throws -> [Message] {

    let query = Message.table
      .select(Message.textField, Message.dateField)
      .where(Message.dateField > lastDateRead)
      .order(Message.dateField.asc)

    let iter = try db.prepareRowIterator(query)

    let messages = try iter.map { msg in
      Message(message: msg[Message.textField],
              date: msg[Message.dateField])
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
