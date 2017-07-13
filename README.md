# Cordova RSACertificate Plugin
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

Note that this cordova plugin is one part of the entire solution. Next
to this part, the part in which the RSA certificate is generated and
is used to encrypt data can be found in github repository xxx.


## <a name="prerequisites"></a>Prerequisites

- Minimum iOS version is 10
- [RSA Certificate and RSA encrypted Data file](https://github.com/just-bi/cordova-plugin-authentication)



## <a name="installation"></a>Installation (CLI)

The plugin needs to know the extensions that are used for the certificate
and for the encrypted data file. These can be provided during the
installation of the plugin. If required, they can be changed later in
the config.xml file of the cordova application.

Variable | Description | Example
--- | --- | ---
CERTIFICATE_EXTENSION | Extension used for RSA certificate | jbc
ENCRYPTEDDATA_EXTENSION | Extension used for the encrypted data file | jbi

The plugin can be installed from the master repo using:
```bash
$ cordova plugin add https://github.com/just-bi/cordova-plugin-rsacertificate --variable CERTIFICATE_EXTENSION=jbc --variable ENCRYPTEDDATA_EXTENSION=jbi --nofetch
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
  function() {
    getData()
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
  cordova plugin add https://github.com/just-bi/cordova-plugin-rsacertificate --variable CERTIFICATE_EXTENSION=jbc --variable ENCRYPTEDDATA_EXTENSION=jbi --nofetch
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
        function () {
          getData()
        }.bind(this),
        function (errorMessage) {
          alert("Error: " + errorMessage)
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
          alert("Error: " + errorMessage)
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