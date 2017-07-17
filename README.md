# Cordova RSA Certificate Plugin
by [Shervin Soleymanpoor](mailto:shervin.soleymanpoor@just-bi.nl)

## Index

1. [Description](#description)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Example](#example)

## <a name="description"></a>Description

This cordova plugin allows the decryption of RSA encrypted data files in
iOS applications. This is done by importing a P12 certificate in the 
application key-chain and using this certificate to decrypted the data
files.

Note that this plugin is only able to decrypt data files using the RSA
certificate. Refer to repository [JS RSA Encryption](https://github.com/just-bi/js-rsaencryption)
for the encryption of data files using the RSA certificate.



## <a name="prerequisites"></a>Prerequisites

- iOS version 10 or later
- RSA Key Pair (public and private key)<br>
  This plugin makes use of RSA encryption. This is a asymmetric algorithm: 
  encryption and decryption is done via different keys. Data is encrypted
  using a RSA public key. The decryption is only possible via the related
  RSA private key. The Cordova Plugin requires this private key in order
  to decrypt data files. The public key is used in the application that
  will create the encrypted data files (see repository [JS RSA Encryption](https://github.com/just-bi/js-rsaencryption))
  
  There are various ways to retrieve a RSA keypair. Below the steps are 
  explained which make use of the KeyChain in MacOS to generate a RSA
  Key-Pair.

  ###### Generate RSA Key Pair via the Key-Chain app in MacOS:
  1. Open the Keychain Access App on MacOS
  2. Choose Keychain Access > Certificate Assistant > Create a Certificate.
  2. Enter a name for the certificate.
  3. Choose for "Self-Signed" identity type
  4. Choose for "S/MIME" certificate type
  5. Check the "Let me override defaults" setting
  6. In the next screen, set the validity period of the certificate
  7. In the next screen, enter your certificate information
  8. Set the key-size to 2048-bits and choose for the RSA algorithm
  9. In the next screen choose for Key Usage Extension "Key encipherment", uncheck "Signature"
  10. In the next screen, uncheck "Include extended key usage extension"
  11. In the next screens, uncheck all options
  12. Store the certificate in "Login"
  
  ###### Export P12 Certificate containing RSA private key:
  1. Open the Keychain Access App on MacOS
  2. Select category "Certificates" from the "Login" keychain
  3. Right mouse-click on the certificate that you just created and select "Export..."
  4. Save the P12-file to a location on your MacOS. During the export, you will be asked for a password to protect the file.
  5. Change the extension from .p12 to your preferred extension which later is mapped to your application during the installation of the Cordova plugin (see [Certificate Extension](certificate_extension)). 
 
  Note:<br>
  Be careful with this file, this contains the private key that is able to decrypt all the data. This file including its password should be kept save.
  
  ###### Export RSA public key:
  1. Open the Keychain Access App on MacOS
  2. Select category "Keys" from the "Login" keychain
  3. Select your created public key (key type is 'public key')
  4. Right mouse-click on the key and select "Export..."
  5. Save the PEM-file to a location on your MacOS



## <a name="installation"></a>Installation (CLI)

This plugin allows users to install certificates and decrypt files. Both 
the certificate and the encrypted data files are provided to the
to the application via the iOS 'Open in...' functionality. In order to
make this work, file extensions need to be mapped to the application.
This mapping is done during the installation of the plugin.

Two variables need to be passed:
- <a name="certificate_extension"></a>CERTIFICATE_EXTENSION<br>
  This is the file extension that will be mapped in order to install the
  certificate. When exporting the certificate from the key chain (which
  is explained in [js-rsaencryption](https://github.com/just-bi/js-rsaencryption)) 
  the file has extension p12. P12 extensions are automatically installed
  in an internal key-chain which is not accessible in the application.
  For that reason, the P12 extension should be changed to something
  else. That 'something else' is what needs to be provided in this
  variable. When receiving a file with that extension (via email or via
  safari), the file will be opened into the application.
  
- ENCRYPTEDDATA_EXTENSION<br>
  Just like the extension for the certificate, a mapping needs to be
  made for the encrypted data files. This extension needs to differ from
  the certificate extension.

The plugin can be installed from the master repo using:
```bash
$ cordova plugin add https://github.com/just-bi/cordova-plugin-rsacertificate --variable CERTIFICATE_EXTENSION=jbc --variable ENCRYPTEDDATA_EXTENSION=jbi
```



## <a name="usage"></a>Usage

The check for new data files should be done everytime the application is started or resumed:

```js
document.addEventListener('deviceready', onApplicationStarted, false);
document.addEventListener('resume', onApplicationStarted, false);

function onApplicationStarted() {
  // insert the cordova authentication plugin code here
}
```


First you'll want to check if a new certificate is imported to the application. This is done via the updateCertificate function. It checks for a file in the Inbox
that has the extension that is defined for the certificates in the configuration of the plugin.

In case a new certificate is found, the certificate is added to the key chain and a message is displayed. Afterwards the success callback in JavaScript is triggered.
When no new certificate was found, the success callback is directly triggered. When anything goes wrong during the check for a new certificate, the error callback is
triggered.

```js
cordova.plugin.rsacertificate.updateCertificate(

  // update of the certificate is done
  function(newCertificateInstalled) {
    if (newCertificateInstalled) {
      cordova.plugin.rsacertificate.deleteDataFiles(
        function() {
          alert("Successfully installed the new cerficate!\n\nPlease select a data file and use the Open in... functionality in order to use this application.")
        }
      )
    } else  {
      getData()
    }
  }.bind(this), 
  
  // something went wrong during the update of the certificate
  function(errorMessage) {
    console.error(errorMessage)
  } 
);
```

Next the function for reading the encrypted data file can be called. This function will check if a file in the Inbox is available with the extension that was
defined for the encrypted datafiles in the configuration of the plugin.
If found, the plugin will try to decrypt the file based on the certificate in the app. If that is possible, the file content will be passed back to JavaScript
as a parameter of the success callback. If something goes wrong, the error callback is triggered having the error message as parameter.

```js
function getData() {
  cordova.plugin.rsacertificate.decryptFile(

    // successfully decrypted the file
    function(fileContent) {
      startYourApplication()
    }, 
  
    // unable to decrypt the file
    function(errorMessage) {
      console.error(errorMessage)
    } 
  );
}
```

Showing a message (either for errors or for instructions to the end user), a specific view is created. This can be used as follows:
  ```js
  function showMessage() {
    cordova.plugin.rsacertificate.showMessage({
      title: "Message Title",
      message: "The message content",
      backgroundColorHex: "FFFFFF",
      textColorHex: "000000"
    });
  }
  ```

For security reasons you may need to remove data files or the certificate. The following functions can be used for that.

- Data Files Only
  ```js
  function deleteDataFiles() {
    cordova.plugin.rsacertificate.deleteDataFiles(
      function() {
        // data files are deleted
      }
    );
  }
  ```

- Certificate Only
  ```js
  function deleteCertificate() {
    cordova.plugin.rsacertificate.deleteCertificate(
      function() {
        // certificate is deleted
      }
    );
  }
  ```

- Both Certificate and Data Files:
  ```js
  function cleanUp() {
    cordova.plugin.rsacertificate.cleanup(
      function() {
        // certificate and data files are deleted
      }
    );
  }
  ```


## <a name="example"></a>Example
- Bootstap a cordova test application
  ```bash
  cordova create testapp com.justbi.testapp TestApp
  cd testapp
  ```

- Add the iOS platform
  ```bash
  cordova platform add ios
  ```

- Add the cordova plugin
  ```bash
  cordova plugin add https://github.com/just-bi/cordova-plugin-rsacertificate --variable CERTIFICATE_EXTENSION=jbc --variable ENCRYPTEDDATA_EXTENSION=jbi
  ```

- Setup the application authentication
  Replace the content of the www/js/index.js file with the following:

  ```js
  document.addEventListener('deviceready', onApplicationStarted, false);
  document.addEventListener('resume', onApplicationStarted, false);
  
  function onApplicationStarted() {
  
      // Function to update the certificate to the iOS key-chain
    function updateCertificate() {
      cordova.plugin.rsacertificate.updateCertificate(
        function (newCertificateInstalled) {
          if (newCertificateInstalled) {
            cordova.plugin.rsacertificate.deleteDataFiles(
              function() {
                cordova.plugin.rsacertificate.showMessage({
                  title: "Certificate",
                  message: "Successfully installed the new cerficate!\n\nPlease select a data file and use the Open in... functionality in order to use this application.",
                  backgroundColorHex: "FFFFFF",
                  textColorHex: "000000"
                });          
              }
            )
          } else  {
            getData()
          }
        }.bind(this),
        function (errorMessage) {
          cordova.plugin.rsacertificate.showMessage({
            title: "Error",
            message: errorMessage,
            backgroundColorHex: "FFFFFF",
            textColorHex: "000000"
          }); 
        }
      )
    }
    
    // Function to decrypt the data file
    function getData() {
      cordova.plugin.rsacertificate.decryptFile(
        function (fileContent) {
          alert(fileContent)
        },
        function (errorMessage) {
          cordova.plugin.rsacertificate.showMessage({
            title: "Error",
            message: errorMessage,
            backgroundColorHex: "FFFFFF",
            textColorHex: "000000"
          }); 
        }
      )
    }
    
    updateCertificate()
  }
  ```

- Build the iOS application
  ```bash
  cordova build ios
  ```