//
//  DatabaseConnection.swift
//  SmartBrush
//
//  Created by Lauren Paicopolis on 11/15/21.
//

import Foundation
import SQLite3

// Error enum that covers four main operations that can fail
enum SQLiteError: Error {
  case OpenDatabase(message: String)
  case Prepare(message: String)
  case Step(message: String)
  case Bind(message: String)
}

// Defines proper struct to represent a value in table (ToothBrushData)
struct ToothBrushData {
    let year: Int32
    let average: Double
    let month: Int32
    let day: Int32
    let time: NSString
    let dayOfWeek: Int32
    let numberOfDaysInMonth: Int32
}

// Wrap database connection pointer in own clas
class SQLiteDatabase {
  // private initializer: instantiation of class w/ path to database versus using OpaquePointer
  private let dbPointer: OpaquePointer?
  private init(dbPointer: OpaquePointer?) {
    self.dbPointer = dbPointer
  }
  deinit {
    sqlite3_close(dbPointer)
  }
    
    static func open() throws -> SQLiteDatabase {
      var db: OpaquePointer?
        let fileURL = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                create: false).appendingPathComponent("ToothBrushDataBase.sqlite")
      // Attempt to open database at provided path
      if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
        // Return a new instance of SQLiteDatabase
        return SQLiteDatabase(dbPointer: db)
      } else {
        // Close the database if not
        defer {
          if db != nil {
            sqlite3_close(db)
          }
        }
        if let errorPointer = sqlite3_errmsg(db) {
          let message = String(cString: errorPointer)
          throw SQLiteError.OpenDatabase(message: message)
        } else {
          throw SQLiteError
            .OpenDatabase(message: "No error message provided from sqlite.")
        }
      }
    }
    
    // Addded a computed property: returns the most recent error SQLite knows about Access SQLite Error messages
    var errorMessage: String {
      if let errorPointer = sqlite3_errmsg(dbPointer) {
        let errorMessage = String(cString: errorPointer)
        return errorMessage
      } else {
        return "No error message provided from sqlite."
      }
    }
}

// Preparing Statements
// Declare that prepare statement can throw an error, use guard to throw error should
// sqlite3_prepare_v2() fails - pass error message from SQLite to case in error enum
extension SQLiteDatabase {
 func prepareStatement(sql: String) throws -> OpaquePointer? {
  var statement: OpaquePointer?
  guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
      == SQLITE_OK else {
    throw SQLiteError.Prepare(message: errorMessage)
  }
  return statement
 }
}

// Create Table
protocol SQLTable {
  static var createStatement: String { get }
}

// Extend ToothBrushData to conform to the new protocol
extension ToothBrushData: SQLTable {
    
    // defines createStatement and adds CREATE TABLE statement
    // on ToothBrushData to keepy code grouped together Id INT, IF NOT EXISTS
  static var createStatement: String {
    return """
        CREATE TABLE IF NOT EXISTS ToothBrushData(
        Year INT,
        Average DOUBLE,
        Month INT,
        Day INT,
        Time CHAR (255),
        DayOfWeek INT,
        NumberOfDaysInMonth INT
    );
    """
  }
}

extension SQLiteDatabase {
  func createTable(table: SQLTable.Type) throws {
    let createTableStatement = try prepareStatement(sql: table.createStatement)
    // Defer ensures statements are always finalized regardless of how
    // method exits its scope
    defer {
      sqlite3_finalize(createTableStatement)
    }
    guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
      throw SQLiteError.Step(message: errorMessage)
    }
    print("\(table) table created.")
  }
}

/* INSERTION INTO TABLE*/
// Prepare statement, bind the values, execute and finalize
extension SQLiteDatabase {
  func insertData(ToothBrushData: ToothBrushData) throws {
    let insertSql = "INSERT INTO ToothBrushData (Year, Average, Month, Day, Time, DayOfWeek, NumberOfDaysInMonth) VALUES (?, ?, ?, ?, ?, ?, ?);"
    let insertStatement = try prepareStatement(sql: insertSql)
    let time: NSString = ToothBrushData.time
    defer {
      sqlite3_finalize(insertStatement)
    }
    guard
            //sqlite3_bind_int(insertStatement, 1, ToothBrushData.id) == SQLITE_OK  &&
            sqlite3_bind_int(insertStatement, 1, ToothBrushData.year) == SQLITE_OK &&
            sqlite3_bind_double(insertStatement, 2, ToothBrushData.average) == SQLITE_OK &&
            sqlite3_bind_int(insertStatement, 3, ToothBrushData.month) == SQLITE_OK &&
            sqlite3_bind_int(insertStatement, 4, ToothBrushData.day) == SQLITE_OK &&
            sqlite3_bind_text(insertStatement, 5, time.utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_int(insertStatement, 6, ToothBrushData.dayOfWeek) == SQLITE_OK &&
            sqlite3_bind_int(insertStatement, 7, ToothBrushData.numberOfDaysInMonth) == SQLITE_OK
      else {
        throw SQLiteError.Bind(message: errorMessage)
    }
    guard sqlite3_step(insertStatement) == SQLITE_DONE else {
      throw SQLiteError.Step(message: errorMessage)
    }
    print("Successfully inserted row.")
  }
}


// Read
// Takes Week, Month, Year of ToothBrushData and either returns ToothBrushData or nil
extension SQLiteDatabase {
    func data(Week: Int32 = 0, Month: Int32 = 0, Year: Int32 = 0) -> Array<ToothBrushData>? {
        var querySql = ""
        var averages: [ToothBrushData] = []
        if (Month == 0) {
            print(Year)
            querySql = "SELECT * FROM ToothBrushData WHERE Year = ?;"
        }
        else {
            querySql = "SELECT * FROM ToothBrushData WHERE Year = ? AND Month = ?;"
        }
    guard let queryStatement = try? prepareStatement(sql: querySql) else {
        return nil
    }
    defer {
      sqlite3_finalize(queryStatement)
    }
    guard sqlite3_bind_int(queryStatement, 1, Year) == SQLITE_OK else {
      return nil
    }
    if (Month != 0) {
        guard sqlite3_bind_int(queryStatement, 2, Month) == SQLITE_OK else {
            return nil
        }
    }
    while (sqlite3_step(queryStatement) == SQLITE_ROW) {
        
        guard sqlite3_column_text(queryStatement, 1) != nil else {
            print("Query result is nil.")
            return nil
        }
        let year = sqlite3_column_int(queryStatement, 0)
        let average = sqlite3_column_double(queryStatement, 1)
        let month = sqlite3_column_int(queryStatement, 2)
        let day = sqlite3_column_int(queryStatement, 3)
        guard let firstTime = sqlite3_column_text(queryStatement, 4) else {
            print("Query result is nil.")
            return nil
        }
        let time = String(cString: firstTime) as NSString
        let dayOfWeek = sqlite3_column_int(queryStatement, 5)
        let totalDaysInMonth = sqlite3_column_int(queryStatement, 6)
        let value = ToothBrushData(year: year, average: average, month: month,
                                   day: day, time: time, dayOfWeek: dayOfWeek, numberOfDaysInMonth: totalDaysInMonth )
        averages.append(value)
    }
    return averages
  }
}

extension SQLiteDatabase {
    func deleteDatabase() {
        let fileURL = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                create: false).appendingPathComponent("ToothBrushDataBase.sqlite")
        let fm = FileManager.default
        do {
            try fm.removeItem(at:fileURL)
        } catch {
            NSLog("Error deleting file: \(fileURL)")
        }
    }
}



