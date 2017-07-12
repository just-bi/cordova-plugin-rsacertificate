import Foundation
import CryptoSwift

class AESHelper {

  // class properties
  var key        : String
  var iv         : String
  let BLOCK_SIZE = 16

  /**
   Class initialization
   **/
  init (key: String, iv: String) {
    self.key = key
    self.iv  = iv
  }

  /**
   Encrypt a string with AES encryption
   **/
  func encrypt (stringToEncrypt: String) -> String {
    let messageData = stringToEncrypt.data(using: String.Encoding.utf8)
    let encryptedBytes = try! AES(key: self.key, iv: self.iv, blockMode: .CFB).encrypt(messageData!)
    return encryptedBytes.toHexString()
  }


  /**
   Decrypt a string with AES encryption
   **/
  func decrypt ( message: String) -> String {
    let messageData = message.hexadecimal()
    let decryptedBytes: [UInt8] = try! AES(key: self.key, iv: self.iv, blockMode: .CFB).decrypt(messageData!)
    let unpaddedBytes = unpad(value: decryptedBytes)
    return NSString(bytes: unpaddedBytes, length: unpaddedBytes.count, encoding: String.Encoding.utf8.rawValue)! as String
  }


  /**
   Pad function for the last block
   **/
  private func pad( value: [UInt8]) -> [UInt8] {
    var value = value
    let length: Int = value.count
    let padSize = BLOCK_SIZE - (length % BLOCK_SIZE)
    let padArray = [UInt8](repeating: 0, count: padSize)
    value.append(contentsOf: padArray)
    return value
  }


  /**
   Unpad function for the last block
   **/
  private func unpad( value: [UInt8]) -> [UInt8] {
    var value = value

    for index in stride(from: value.count - 1, through: 0, by: -1) {
      if value[index] == 0 {
        value.remove(at: index)
      } else  {
        break
      }
    }
    return value
  }
}


/**
 Extension of the String type
 **/
extension String {

  /**
   Conversion from String to Hexadecimal
   **/
  func hexadecimal() -> Data? {
    var data = Data(capacity: characters.count / 2)

    let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
    regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
      let byteString = (self as NSString).substring(with: match!.range)
      var num = UInt8(byteString, radix: 16)!
      data.append(&num, count: 1)
    }

    guard data.count > 0 else { return nil }
    return data
  }

}
