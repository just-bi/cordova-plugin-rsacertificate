import CryptoSwift

@available(iOS 10.0, *)
@objc(RSACertificatePlugin) class RSACertificatePlugin : CDVPlugin {
  @objc(updateCertificate:)
  public func updateCertificate(command: CDVInvokedUrlCommand) {
    let certificateFileExtension = self.commandDelegate.settings["rsacertificateextension"] as? String ?? "jbc"


    self.commandDelegate.run(inBackground: {

      // Verify if a file with the certificate file extension is available in the Inbox folder
      let inboxUrl = FileService.getPathToInboxFolder()
      guard let certificateFilePath = FileService.getURLToFirstFileInDirectoryByExtension(
        directoryPath : inboxUrl,
        fileExtension : certificateFileExtension
        )
        else {
          self.commandDelegate!.send(
            CDVPluginResult(
              status    : CDVCommandStatus_OK,
              messageAs : false
            ),
            callbackId: command.callbackId
          )
          return
      }


      // Import the certificate
      func onImportDone(success: Bool, message: String, retryPossible: Bool) {
        if success {
          _ = FileService.deleteAllFilesInDirectoryByExtension(
            directoryPath : inboxUrl,
            fileExtension : certificateFileExtension
          )

          self.commandDelegate!.send(
            CDVPluginResult(
              status    : CDVCommandStatus_OK,
              messageAs : true
            ),
            callbackId: command.callbackId
          )

          return
        }

        if retryPossible {
          AlertService.showCancelRetryMessage(
            viewController : self.viewController!,
            title          : "Password",
            message        : message,
            onRetry        : {_ in
              self.importCertificate(
                certificateFilePath      : certificateFilePath,
                certificateFileExtension : certificateFileExtension,
                onImportDone             : onImportDone
              )
          },
            onCancel : {_ in
              _ = FileService.deleteAllFilesInDirectoryByExtension(
                directoryPath : inboxUrl,
                fileExtension : certificateFileExtension
              )

              self.commandDelegate!.send(
                CDVPluginResult(
                  status    : CDVCommandStatus_ERROR,
                  messageAs : "Certificate import process canceled by user."
                ),
                callbackId: command.callbackId
              )
          }
          )
          return
        }

        _ = FileService.deleteAllFilesInDirectoryByExtension(
          directoryPath : inboxUrl,
          fileExtension : certificateFileExtension
        )

        self.commandDelegate!.send(
          CDVPluginResult(
            status    : CDVCommandStatus_ERROR,
            messageAs : message
          ),
          callbackId: command.callbackId
        )

      }


      // import the certificate
      self.importCertificate(
        certificateFilePath      : certificateFilePath,
        certificateFileExtension : certificateFileExtension,
        onImportDone             : onImportDone
      )

    })
  }


  /**
   Import the provided certificate into the key chain
   **/
  private func importCertificate(
    certificateFilePath       : URL,
    certificateFileExtension  : String,
    onImportDone : @escaping ((
    _ success       : Bool, _ message: String,
    _ retryPossible : Bool) -> Void
    )
    ) -> Void {


    // after having the certificate passphrase, follow the steps to import the
    // certificate into the key chain
    func onCertificatePasswordProvided(
      certificatePassphrase: String,
      onImportDone : ((
      _ success: Bool,
      _ message: String,
      _ retryPossible: Bool
      ) -> Void)
      ) -> Void {

      // check if the passphrase is provided
      if certificatePassphrase == "" {
        onImportDone (
          false,
          "The certificate is protected with a password, please enter the password to complete the import process.",
          true
        )
        return
      } else if certificatePassphrase == "__canceled__" {
        onImportDone (
          false,
          "Certificate import process canceled by user.",
          false
        )
        return
      }


      // read the certificate content from the file data
      let p12CertificateData     = NSData(contentsOf: certificateFilePath)
      var importResult: CFArray? = nil
      switch SecPKCS12Import(
        p12CertificateData!,
        [kSecImportExportPassphrase as String: certificatePassphrase] as NSDictionary,
        &importResult
      ) {
      case noErr:
        break;
      case errSecAuthFailed:
        onImportDone (
          false,
          "The provided password is incorrect. Please use the 'Retry' button to provide the correct password.",
          true
        )
        return;
      default:
        onImportDone (
          false,
          "Unable to import the certificate.",
          false
        )
        return;
      }


      // extract the identity from the PKCS12 file
      let p12ImportResults = importResult! as! Array<Dictionary<String, Any>>
      let p12Identity = p12ImportResults[0][kSecImportItemIdentity as String] as! SecIdentity?

      // extract the private key from the identity
      var privateKey : SecKey? = nil
      guard SecIdentityCopyPrivateKey(p12Identity!, &privateKey) == errSecSuccess
        else {
          onImportDone (
            false,
            "Certificate does not contain a private key",
            false
          )
          return
      }


      // delete any old private key (if existing) from the key-chain
      let deleteQuery: [String: Any] = [
        kSecClass               as String: kSecClassKey,
        kSecAttrType            as String: kSecAttrKeyTypeRSA,
        kSecAttrKeyClass        as String: kSecAttrKeyClassPrivate,
        kSecAttrApplicationTag  as String: AppParams.cSecAttrApplicationTag
      ]
      SecItemDelete(deleteQuery as CFDictionary)


      // add the new private key to the key-chain
      let addQuery: [String: Any] = [
        kSecClass               as String: kSecClassKey,
        kSecValueRef            as String: privateKey!,
        kSecAttrType            as String: kSecAttrKeyTypeRSA,
        kSecAttrKeyClass        as String: kSecAttrKeyClassPrivate,
        kSecAttrApplicationTag  as String: AppParams.cSecAttrApplicationTag
      ]
      let statusStorePrivateKey = SecItemAdd(addQuery as CFDictionary, nil)
      guard statusStorePrivateKey == errSecSuccess else {
        onImportDone (
          false,
          "Unable to store the private key in the application key-chain",
          false
        )
        return
      }

      onImportDone (true, "", false)
      return
    }

    // Get the password for the certificate
    askForCertificatePassword(
      onPasswordEntered : onCertificatePasswordProvided,
      onImportDone      : onImportDone
    )
  }



  /**
   Ask the user for the certification password
   **/
  func askForCertificatePassword(
    onPasswordEntered: @escaping (
    _ message:String,
    _ onImportDone: ((
    _ success: Bool,
    _ message: String,
    _ retryPossible: Bool) -> Void)
    ) -> Void,
    onImportDone : @escaping ((
    _ success: Bool,
    _ message: String,
    _ retryPossible: Bool
    ) -> Void)
    ) -> Void {

    // create the alert
    let alert = UIAlertController(
      title          : "Import Certificate",
      message        : "Enter the password to complete the import process:",
      preferredStyle : .alert
    )

    // add a password field to the alert view
    alert.addTextField { (textField) in
      textField.placeholder = "Password"
    }

    // add two buttons: OK and Cancel
    alert.addAction(
      UIAlertAction(
        title: "OK",
        style: .default,
        handler: {
          _ in
          let enteredPassword = alert.textFields![0].text
          onPasswordEntered(
            enteredPassword!,
            onImportDone
          )
      }
      )
    )
    alert.addAction(
      UIAlertAction(
        title: "Cancel",
        style: .cancel,
        handler: {
          _ in
          onPasswordEntered(
            "__canceled__",
            onImportDone
          )
      }
      )
    )

    // show the alert
    self.viewController!.present(
      alert,
      animated   : true,
      completion : nil
    )
  }



  /**
   Clean up the application by removing the data files and the certificate
   **/
  @objc(cleanup:)
  public func cleanup(command: CDVInvokedUrlCommand) {
    self.deleteDataFiles()
    self.deleteCertificate()

    // Done
    self.commandDelegate!.send(
      CDVPluginResult(
        status    : CDVCommandStatus_OK
      ),
      callbackId: command.callbackId
    )
  }


  /**
   Delete the data files from the application
   **/
  @objc(deleteDataFiles:)
  public func deleteDataFiles(command: CDVInvokedUrlCommand) {
    self.deleteDataFiles()

    // Done
    self.commandDelegate!.send(
      CDVPluginResult(
        status    : CDVCommandStatus_OK
      ),
      callbackId: command.callbackId
    )
  }


  /**
   Delete the certificate from the application
   **/
  @objc(deleteCertificate:)
  public func deleteCertificate(command: CDVInvokedUrlCommand) {
    self.deleteCertificate()

    // Done
    self.commandDelegate!.send(
      CDVPluginResult(
        status    : CDVCommandStatus_OK
      ),
      callbackId: command.callbackId
    )
  }


  /**
   Delete the data files from the application
   **/
  private func deleteDataFiles() {
    let rsaEncryptedFileExtension = self.commandDelegate.settings["rsaencryptedfileextension"] as? String ?? "jbi"

    // remove data files from the inbox folder
    let inboxUrl = FileService.getPathToInboxFolder()
    _ = FileService.deleteAllFilesInDirectoryByExtension(directoryPath: inboxUrl, fileExtension: rsaEncryptedFileExtension)

    // remove data files from the document folder
    let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    _ = FileService.deleteAllFilesInDirectoryByExtension(directoryPath: documentsUrl, fileExtension: rsaEncryptedFileExtension)
  }


  /**
   Delete the certificate from the application
   **/
  private func deleteCertificate() {
    let certificateFileExtension = self.commandDelegate.settings["rsacertificateextension"] as? String ?? "jbc"

    // remove data files from the inbox folder
    let inboxUrl = FileService.getPathToInboxFolder()
    _ = FileService.deleteAllFilesInDirectoryByExtension(directoryPath: inboxUrl, fileExtension: certificateFileExtension)

    // remove certificate from the key-chain
    let deleteQuery: [String: Any] = [
      kSecClass               as String: kSecClassKey,
      kSecAttrType            as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass        as String: kSecAttrKeyClassPrivate,
      kSecAttrApplicationTag  as String: AppParams.cSecAttrApplicationTag
    ]
    SecItemDelete(deleteQuery as CFDictionary)

  }








  /**
   Decrypt the data file
   **/
  @objc(decryptFile:)
  public func decryptFile(command: CDVInvokedUrlCommand) {
    let rsaEncryptedFileExtension = self.commandDelegate.settings["rsaencryptedfileextension"] as? String ?? "jbi"

    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))


    // show decrypting message
    func showIndicator(_ title: String) {
      strLabel.removeFromSuperview()
      activityIndicator.removeFromSuperview()
      effectView.removeFromSuperview()

      strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 65))
      strLabel.text = title
      strLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
      strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)


      effectView.frame = CGRect(
        x: self.webView.frame.midX - strLabel.frame.width/2,
        y: self.webView.frame.midY - strLabel.frame.height/2 ,
        width: 200,
        height: 65)
      effectView.layer.cornerRadius = 15
      effectView.layer.masksToBounds = true


      activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
      activityIndicator.frame = CGRect(x: 0, y: strLabel.frame.height/2 - 23, width: 46, height: 46)
      activityIndicator.startAnimating()

      effectView.addSubview(activityIndicator)
      effectView.addSubview(strLabel)
      self.webView.addSubview(effectView)
    }


    showIndicator("Decrypting File...")

    self.commandDelegate.run(inBackground: {

      // move the inbox data file to a generic name
      let inboxUrl = FileService.getPathToInboxFolder()
      let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      let encryptedFilePath = documentsUrl.appendingPathComponent(AppParams.cEncryptedDataFileName + ".\(rsaEncryptedFileExtension)")
      guard FileService.moveAllFilesInDirectoryWithExtensionToNewLocation(
        directoryPath : inboxUrl,
        fileExtension : rsaEncryptedFileExtension,
        newLocation   : encryptedFilePath
        ) == true
        else {
          DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
          }

          self.commandDelegate!.send(
            CDVPluginResult(
              status    : CDVCommandStatus_ERROR,
              messageAs : "Unable to move the data files from the Inbox folder"
            ),
            callbackId: command.callbackId
          )
          return
      }


      // check if the data file exists
      if !FileService.fileExists(filePath: encryptedFilePath.path) {
        DispatchQueue.main.async {
          effectView.removeFromSuperview()
        }

        self.commandDelegate!.send(
          CDVPluginResult(
            status    : CDVCommandStatus_OK
          ),
          callbackId: command.callbackId
        )
        return
      }


      // read the encrypted file content
      let encryptedFileContent : String;
      do {
        encryptedFileContent = try String(contentsOf: encryptedFilePath, encoding: String.Encoding.utf8)
      }catch {
        _ = FileService.deleteFile(filePath: encryptedFilePath.path)
        DispatchQueue.main.async {
          effectView.removeFromSuperview()
        }

        self.commandDelegate!.send(
          CDVPluginResult(
            status    : CDVCommandStatus_ERROR,
            messageAs : "Unable to read the encrypted file contents."
          ),
          callbackId: command.callbackId
        )
        return
      }


      // the encrypted file in in JSON format, containing the RSA encrypted AES key and
      // the message itself which is AES encrypted. Split the RSA encrytped key and the
      // message
      let encryptedData = encryptedFileContent.data(using: .utf8)
      guard let encryptedDictionary : [String: Any] = try? JSONSerialization.jsonObject(with: encryptedData!, options: []) as! [String: Any]
        else {
          _ = FileService.deleteFile(filePath: encryptedFilePath.path)
          DispatchQueue.main.async {
            effectView.removeFromSuperview()
          }

          self.commandDelegate!.send(
            CDVPluginResult(
              status    : CDVCommandStatus_ERROR,
              messageAs : "Unable to parse the encrypted file."
            ),
            callbackId: command.callbackId
          )
          return
      }


      // decrypt the message
      let rsaEncryptedAESPassAndIvString = encryptedDictionary["key"] as! String
      let aesEncryptedMessageString      = encryptedDictionary["text"] as! String
      let (success, errorMessage, decryptedMessage) = self.decryptText(rsaEncryptedAESPassAndIvString: rsaEncryptedAESPassAndIvString, aesEncryptedMessageString: aesEncryptedMessageString)
      if !success {
        _ = FileService.deleteFile(filePath: encryptedFilePath.path)
        DispatchQueue.main.async {
          effectView.removeFromSuperview()
        }

        self.commandDelegate!.send(
          CDVPluginResult(
            status    : CDVCommandStatus_ERROR,
            messageAs : errorMessage
          ),
          callbackId: command.callbackId
        )
        return
      }


      // parse the JSON object on this part
      DispatchQueue.main.async {
        effectView.removeFromSuperview()
      }

      self.commandDelegate!.send(
        CDVPluginResult(
          status    : CDVCommandStatus_OK,
          messageAs : decryptedMessage
        ),
        callbackId: command.callbackId
      )

    })
  }





  /**
   RSA and AES
   The provided text is encrypted using the AES encryption technique. This type of encryption
   can be used for encrypting bulk data. The encryption and decryption of text via AES is done
   via the same password and initialization vector (iv). This is called symmetric encryption.

   Next to the text, the password and iv are provided to this function. These are encrypted via
   the RSA encrypting technique. This type encryption requires a key-pair: one or multiple
   public keys that can be used for encrypting data and one private key for decrypting data
   which was encypted via the related public key.

   In this application the following steps are executed:
   1. Retrieval of the RSA private key
   2. RSA decryption of the concatenated password and iv, using the RSA private key
   3. Splitting the concatenated password and iv
   4. AES decryption of the text, using the password and iv
   **/

  private func decryptText(rsaEncryptedAESPassAndIvString: String, aesEncryptedMessageString: String) -> (success: Bool, errorMessage: String, decryptedMessage: String) {


    /**
     1. RETRIEVAL OF THE RSA PRIVATE KEY
     **/

    // create a query fo the key chain
    let getquery: [String: Any] = [
      kSecClass               as String: kSecClassKey,
      kSecAttrType            as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass        as String: kSecAttrKeyClassPrivate,
      kSecAttrApplicationTag  as String: AppParams.cSecAttrApplicationTag,
      kSecReturnRef           as String: kCFBooleanTrue,
      ]

    // execute the query and check if the private key was found
    var item: CFTypeRef?
    let status = SecItemCopyMatching(getquery as CFDictionary, &item)
    guard status == errSecSuccess else {
      return (
        success          : false,
        errorMessage     : "The certificate for decrypting the provided data file could not be found. Contact your system administrator in order to get the certificate.",
        decryptedMessage : ""
      )
    }
    let myPrivateKey = item as! SecKey



    /**
     2. RSA DECRYPTION OF THE CONCATENATED PASSWORD AND IV, USING THE RSA PRIVATE KEY
     **/

    // cast the base64 string to data
    guard
      let rsaEncryptedAESPassAndIvData = Data(base64Encoded: rsaEncryptedAESPassAndIvString, options: [])
      else {
        return (
          success          : false,
          errorMessage     : "Unable to cast the RSA encrypted AES key from base64 string to data.",
          decryptedMessage : ""
        )
    }
    // decrypt the encrypted AES password and initialization vector
    guard
      let aesPassAndIvData = SecKeyCreateDecryptedData(
        myPrivateKey,
        .rsaEncryptionOAEPSHA512,
        rsaEncryptedAESPassAndIvData as CFData,
        nil)
      else {
        return (
          success          : false,
          errorMessage     : "Unable to decrypt the provided data file with your installed certificate.",
          decryptedMessage : ""
        )
    }

    // cast the decrypted AES pass and IV from data to NSString
    guard
      let aesPassAndIvNSString = NSString(
        data: aesPassAndIvData as Data,
        encoding: String.Encoding.utf8.rawValue
      )
      else {
        return (
          success          : false,
          errorMessage     : "Unable to cast the AES pass and IV from data to NSString.",
          decryptedMessage : ""
        )
    }

    // cast the decrypted AES pass and IV from NSString to String
    let aesPassAndIvString = aesPassAndIvNSString as String



    /**
     3. SPLITTING THE CONCATENATED PASSWORD AND IV
     **/

    // the password and the initialization vector should be of the same length
    let passwordLength = aesPassAndIvString.characters.count / 2


    // the first part of the string is the password
    let aesPassString  = aesPassAndIvString.substring(
      to: aesPassAndIvString.index(
        aesPassAndIvString.startIndex,
        offsetBy : passwordLength
      )
    )

    // the second part of the string is the initialization vector
    let aesIvSting   = aesPassAndIvString.substring(
      from: aesPassAndIvString.index(
        aesPassAndIvString.startIndex,
        offsetBy: passwordLength
      )
    )


    /**
     4. AES DECRYPTION OF THE TEXT, USING PASSWORD AND INITIALIZATION VECTOR
     **/

    // decrypt the message
    let aesEncryptedMessageData = Data(base64Encoded: aesEncryptedMessageString)!
    let messageBytes: [UInt8]   = try! AES(key: aesPassString, iv: aesIvSting, blockMode: .CFB).decrypt(aesEncryptedMessageData)
    let messageData = Data(messageBytes)


    // cast the decrypted message from data to String
    guard let messageString = String(bytes: messageData.bytes, encoding: .utf8)
      else {
        return (
          success          : false,
          errorMessage     : "Unable to cast the decrypted message bytes to string.",
          decryptedMessage : ""
        )
    }

    // show the decrypted message in the interface
    return (
      success          : true,
      errorMessage     : "",
      decryptedMessage : messageString
    )

  }

}