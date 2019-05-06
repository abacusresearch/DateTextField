//
//  DateTextField.swift
//  DateTextField
//
//  Created by Beau Nouvelle on 19/3/17.
//  Copyright © 2017 Beau Nouvelle. All rights reserved.
//

import UIKit
import Foundation

protocol DateTextFieldDelegate: class {
  func dateDidChange(dateTextField: DateTextField)
}

@objcMembers
public class DateTextField: UITextField {
  
  public enum Format: String {
    case monthYear = "MM'$'yyyy"
    case dayMonthYear = "dd'*'MM'$'yyyy"
    case monthDayYear = "MM'$'dd'*'yyyy"
    case hourMinute = "HH'$'mm"
  }
  
  // MARK: - Properties
  private let dateFormatter = DateFormatter()
  
  /// The order for which the date segments appear. e.g. "day/month/year", "month/day/year", "month/year"
  /// **Default:** `Format.dayMonthYear`
  public var dateFormat:Format = Format.dayMonthYear
  
  /// The symbol you wish to use to separate each date segment. e.g. "01 - 01 - 2012", "01 / 03 / 2019"
  /// **Default:** `" / "`
  public var separator: String = "."
  weak var customDelegate: DateTextFieldDelegate?
  
  /// Parses the `text` property into a `Date` and returns that date if successful.
  public var date: Date? {
    get {
      let replacedFirstSymbol = dateFormat.rawValue.replacingOccurrences(of: "$", with: separator)
      let format = replacedFirstSymbol.replacingOccurrences(of: "*", with: separator)
      dateFormatter.dateFormat = format
      return dateFormatter.date(from: text ?? "")
    }
    set {
      if newValue != nil {
        let replacedFirstSymbol = dateFormat.rawValue.replacingOccurrences(of: "$", with: separator)
        let format = replacedFirstSymbol.replacingOccurrences(of: "*", with: separator)
        dateFormatter.dateFormat = format
        text = dateFormatter.string(from: newValue!)
      } else {
        text = nil
      }
    }
  }
  
  // MARK: - Lifecycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  private func setup() {
    super.delegate = self
    keyboardType = .numberPad
    autocorrectionType = .no
  }
  
  func numberOnlyString(with string: String) -> String? {
    let expression = NSRegularExpression.MatchingOptions(rawValue: 0)
    let range = NSRange(location: 0, length: string.count)
    let digitOnlyRegex = try? NSRegularExpression(pattern: "[^0-9]+",
                                                  options: NSRegularExpression.Options(rawValue: 0))
    return digitOnlyRegex?.stringByReplacingMatches(in: string, options: expression, range: range, withTemplate: "")
  }
  
}

// MARK: - UITextFieldDelegate
extension DateTextField: UITextFieldDelegate {
  
  public func textField(
    _ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    
    if string.count == 0 {
      customDelegate?.dateDidChange(dateTextField: self)
      return true
    }
    
    guard let swiftRange = textField.text?.getRange(from: range) else {
      return false
    }
    guard let replacedString = textField.text?.replacingCharacters(in: swiftRange, with: string) else {
      return false
    }
    
    // Because you never know what people will paste in here, and some emoji have numbers present.
    let emojiFreeString = replacedString.stringByRemovingEmoji()
    guard let numbersOnly = numberOnlyString(with: emojiFreeString) else {
      return false
    }
    let forceEndGroup = replacedString.hasSuffix(separator)
    switch dateFormat {
    case .monthYear:
      guard numbersOnly.count <= 6 else { return false }
      let splitString = split(string: numbersOnly, format: [2, 4])
      let month = splitString.count > 0 ? splitString[0] : ""
      let year = splitString.count > 1 ? splitString[1] : ""
      textField.text = final(day: "", month: month, year: year, force: forceEndGroup)
    case .dayMonthYear:
      guard numbersOnly.count <= 8 else { return false }
      let splitString = split(string: numbersOnly, format: [2, 2, 4])
      let day = splitString.count > 0 ? splitString[0] : ""
      let month = splitString.count > 1 ? splitString[1] : ""
      let year = splitString.count > 2 ? splitString[2] : ""
      textField.text = final(day: day, month: month, year: year, force: forceEndGroup)
    case .monthDayYear:
      guard numbersOnly.count <= 8 else { return false }
      let splitString = split(string: numbersOnly, format: [2, 2, 4])
      let day = splitString.count > 1 ? splitString[1] : ""
      let month = splitString.count > 0 ? splitString[0] : ""
      let year = splitString.count > 2 ? splitString[2] : ""
      textField.text = final(day: day, month: month, year: year, force: forceEndGroup)
    case .hourMinute:
      guard numbersOnly.count <= 4 else { return false }
      let splitString = split(string: numbersOnly, format: [2, 2])
      let hour = splitString.count > 0 ? splitString[0] : ""
      let minute = splitString.count > 1 ? splitString[1] : ""
      textField.text = finalHour(hour: hour, minute: minute, force: forceEndGroup)
    }
    customDelegate?.dateDidChange(dateTextField: self)
    return false
  }
  
  func split(string: String, format: [Int]) -> [String] {
    
    var mutableString = string
    var splitString = [String]()
    
    for item in format {
      if mutableString.count == 0 {
        break
      }
      if mutableString.count >= item {
        let index = string.index(mutableString.startIndex, offsetBy: item)
        splitString.append(String(mutableString[..<index]))
        mutableString.removeSubrange(Range(uncheckedBounds: (mutableString.startIndex, index)))
      } else {
        splitString.append(mutableString)
        mutableString.removeSubrange(Range(uncheckedBounds: (mutableString.startIndex, mutableString.endIndex)))
      }
    }
    
    return splitString
  }
  
  func final(day: String, month: String, year: String, force: Bool) -> String {
    
    var dateString = dateFormat.rawValue
    var aMonth = month
    var aDay = day
    var aForce = force
    dateString = dateString.replacingOccurrences(of: "yyyy", with: year)
    
    if day.count >= 2 {
      if let x = Int(day), x <= 31 {
        dateString = dateString.replacingOccurrences(of: "dd", with: aDay)
        dateString = dateString.replacingOccurrences(of: "*", with: separator)
      }
      else {
        let index = aDay.index(aDay.startIndex, offsetBy: 1)
        let substring = aDay[index]
        dateString = dateString.replacingOccurrences(of: "dd", with: String(substring))
        dateString = dateString.replacingOccurrences(of: "*", with: "")
      }
    } else {
      if (aDay > "3") {
        aDay = "0" + aDay
        dateString = dateString.replacingOccurrences(of: "dd", with: aDay)
        dateString = dateString.replacingOccurrences(of: "*", with: separator)
      }
      else {
        if (aForce) {
          if (aDay.count == 1) {
            aDay = "0" + aDay
          }
          dateString = dateString.replacingOccurrences(of: "dd", with: aDay)
          dateString = dateString.replacingOccurrences(of: "*", with: separator)
          aForce = false
        }
        else {
          dateString = dateString.replacingOccurrences(of: "dd", with: aDay)
          dateString = dateString.replacingOccurrences(of: "*", with: "")
        }
      }
    }
    
    if aMonth.count >= 2 {
      if let x = Int(month), x <= 12 {
        dateString = dateString.replacingOccurrences(of: "MM", with: aMonth)
        dateString = dateString.replacingOccurrences(of: "$", with: separator)
      }
      else {
        let index = aMonth.index(before: aMonth.endIndex)
        let substring = aMonth[index]
        dateString = dateString.replacingOccurrences(of: "MM", with: String(substring))
        dateString = dateString.replacingOccurrences(of: "$", with: "")
      }
    } else {
      if (aMonth > "1") {
        aMonth = "0" + aMonth
        dateString = dateString.replacingOccurrences(of: "MM", with: aMonth)
        dateString = dateString.replacingOccurrences(of: "$", with: separator)
      }
      else {
        if (aForce) {
          if (aMonth.count == 1) {
            aMonth = "0" + aMonth
          }
          dateString = dateString.replacingOccurrences(of: "MM", with: aMonth)
          dateString = dateString.replacingOccurrences(of: "$", with: separator)
          aForce = false
        }
        else {
          dateString = dateString.replacingOccurrences(of: "MM", with: aMonth)
          dateString = dateString.replacingOccurrences(of: "$", with: "")
        }
      }
    }
    
    return dateString.replacingOccurrences(of: "'", with: "")
  }
  
  func finalHour(hour: String, minute: String, force: Bool) -> String {
    var dateString = dateFormat.rawValue
    var aMinute = minute
    var aHour = hour
    var aForce = force

    if aHour.count >= 2 {
      if (aMinute > "5" && aMinute.count == 1) {
        aMinute = "0" + aMinute
      }
      if let h = Int(aHour), h <= 23 {
        // do nothing
      }
      else {
        aHour = "23"
      }
      dateString = dateString.replacingOccurrences(of: "mm", with: aMinute)
      dateString = dateString.replacingOccurrences(of: "HH", with: aHour)
      dateString = dateString.replacingOccurrences(of: "$", with: separator)
    } else {
      dateString = dateString.replacingOccurrences(of: "mm", with: aMinute)
      if (aHour > "2") {
        aHour = "0" + aHour
        dateString = dateString.replacingOccurrences(of: "HH", with: aHour)
        dateString = dateString.replacingOccurrences(of: "$", with: separator)
      }
      else {
        if (aForce) {
          if (aHour.count == 1) {
            aHour = "0" + aHour
          }
          dateString = dateString.replacingOccurrences(of: "HH", with: aHour)
          dateString = dateString.replacingOccurrences(of: "$", with: separator)
          aForce = false
        }
        else {
          dateString = dateString.replacingOccurrences(of: "HH", with: aHour)
          dateString = dateString.replacingOccurrences(of: "$", with: "")
        }
      }
    }
    
    return dateString.replacingOccurrences(of: "'", with: "")
  }
}

// MARK: - String Extension
extension String {
  
  fileprivate func getRange(from nsRange: NSRange) -> Range<String.Index>? {
    guard
      let from16 = utf16.index(utf16.startIndex,
                               offsetBy: nsRange.location,
                               limitedBy: utf16.endIndex),
      let to16 = utf16.index(utf16.startIndex,
                             offsetBy: nsRange.location + nsRange.length,
                             limitedBy: utf16.endIndex),
      let start = from16.samePosition(in: self),
      let end = to16.samePosition(in: self)
      else { return nil }
    return start ..< end
  }
  
  fileprivate func stringByRemovingEmoji() -> String {
    return String(self.filter { !$0.isEmoji() })
  }
  
}

// MARK: - Character Extension
extension Character {
  fileprivate func isEmoji() -> Bool {
    return Character(UnicodeScalar(UInt32(0x1d000))!) <= self && self <= Character(UnicodeScalar(UInt32(0x1f77f))!)
      || Character(UnicodeScalar(UInt32(0x2100))!) <= self && self <= Character(UnicodeScalar(UInt32(0x26ff))!)
  }
}











public class HourTextField: DateTextField {

  override public var dateFormat: Format {
    get {
      return Format.hourMinute
    }
    set {
       // do nothing
    }
  }

}
