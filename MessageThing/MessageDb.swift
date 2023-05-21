//
//  db.swift
//  MessageThing
//
//  Created by Peter Eddy on 5/21/23.
//

import Foundation
import SQLite3

class MessageDb {

  var dbPath = "/Users/petere/work/messages/chat.db"
  
  func withDb<T>(fn: (OpaquePointer) -> T?) -> T? {
    var db: OpaquePointer?
    
    let dbResult = sqlite3_open(dbPath, &db)
    if (dbResult == SQLITE_OK) {
      print("Opened db at \(dbPath)")
      let result = fn(db!)
      sqlite3_close(db)
      return result
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
      if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) != 0 {
        result = fn(queryStatement!)
      }
      sqlite3_finalize(queryStatement)
      return result
    })
  }
  
  func getUnreadTexts() -> [String]? {
    let messageQuery = "SELECT text from messsage;"
    var result = [String]()

    withQuery(query: messageQuery, fn:{ q in
      while sqlite3_step(q) == SQLITE_ROW {
        if let msg = sqlite3_column_text(q, 1) {
          result.append(String(cString: msg))
        }
      }
    })

    return result
  }
}
