//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
  case OpenDatabase(message: String)
  case Prepare(message: String)
  case Step(message: String)
  case Bind(message: String)
}

struct MessageData {
  let message: String
  let date: Int64
  let attributedString: NSAttributedString?
}

class MessageDb {
  var dbPath = "/Users/petere/work/messages/chat.db"

  func errorMessage(db: OpaquePointer) -> String {
    if let errorPointer = sqlite3_errmsg(db) {
      return String(cString: errorPointer)
    }
    return "No Error"
  }

  func withDb<T>(fn: (OpaquePointer) -> T?) -> T? {
    var db: OpaquePointer?
    
    let dbResult = sqlite3_open(dbPath, &db)
    defer {
      sqlite3_close(db)
    }
    if (dbResult == SQLITE_OK) {
      print("Opened db at \(dbPath)")
      return fn(db!)
    }
    if let errorPointer = sqlite3_errmsg(db) {
      let message = String(cString: errorPointer)
      print("Couldn't open db \(dbPath), error: \(message)")
    }
    else {
      print("Couldn't open db \(dbPath), error: \(dbResult)")
    }
    return nil
  }

  func withQuery<T>(query: String, fn: (OpaquePointer) -> T?) -> T? {
    var queryStatement: OpaquePointer?
    
    return withDb(fn: { db in
      var result: T?
      if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
        result = fn(queryStatement!)
      }
      defer {
        sqlite3_finalize(queryStatement)
      }
      print(errorMessage(db: db))
      return result
    })
  }
  
  func getUnreadTexts() -> [MessageData]? {
    let date = Date(timeIntervalSinceNow: -240)
    let messageQuery = """
      SELECT
        text,
        date
      FROM message
      -- WHERE date > \(date.timeIntervalSince1970)
      ORDER BY date;
      """
    var result = [MessageData]()
  
    withQuery(query: messageQuery, fn:{ q in
      while sqlite3_step(q) == SQLITE_ROW {
        if let msg = sqlite3_column_text(q, 0) {
          result.append(
            MessageData(message: String(cString: msg),
                        date: sqlite3_column_int64(q, 1),
                        attributedString: nil)
          )
        }
      }
    })

    return result
  }
}
