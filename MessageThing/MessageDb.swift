//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import GRDB

public struct Message {
  let text: String?
  let date: Int64?
//  let attributedString: NSAttributedString?
  static let query = """
        SELECT
          text,
          date
        FROM message
        ORDER BY date;
        """
}

extension Message: Codable, FetchableRecord, MutablePersistableRecord { }

class MessageDb {
  let dbPath: String
  var dbQueue: DatabaseQueue
  
  // "/Users/petere/Library/Messages/chat.db"

  init?(dbPath: String = "/Users/petere/work/messages/chat.db") {
    self.dbPath = dbPath
    
    var config = Configuration()
    config.readonly = true
    config.maximumReaderCount = 2
    #if DEBUG
    config.publicStatementArguments = true
    #endif

    do {
      try self.dbQueue = DatabaseQueue(path: dbPath, configuration: config)
    }
    catch {
      return nil
    }
  }
  
  func readMessages() -> [Message] {
    do {
      return try dbQueue.read { db in
        try Message.fetchAll(db)
      }
    }
    catch {
      return []
    }
  }
}
