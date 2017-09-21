import Foundation


class CommonService {
  
  static func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
      cString.remove(at: cString.startIndex)
    }
    
    if ((cString.characters.count) != 6) {
      return UIColor.gray
    }
    
    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)
    
    return UIColor(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }
  
  
  static func shakeTextField (textField : UITextField, numberOfShakes : Int, direction: CGFloat, maxShakes : Int) {
    let interval : TimeInterval = 0.03
    UIView.animate(withDuration: interval, animations: { () -> Void in
      textField.transform = CGAffineTransform(translationX: 5 * direction, y: 0)
    }, completion: { (aBool :Bool) -> Void in
      if (numberOfShakes >= maxShakes) {
        textField.transform = CGAffineTransform.identity
        textField.becomeFirstResponder()
        return
      }
      self.shakeTextField( textField: textField, numberOfShakes: numberOfShakes + 1, direction: direction * -1, maxShakes: maxShakes )
    })
  }
  
  
  static func sha256(data : Data) -> Data {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
      _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    return Data(bytes: hash)
  }
  
}
