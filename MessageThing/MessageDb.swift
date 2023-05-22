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
  
  func getUnreadTexts() -> [String]? {
    let messageQuery = "SELECT text from message;"
    var result = [String]()

    withQuery(query: messageQuery, fn:{ q in
      while sqlite3_step(q) == SQLITE_ROW {
        if let msg = sqlite3_column_text(q, 0) {
          result.append(String(cString: msg))
        }
      }
    })

    return result
  }
}
