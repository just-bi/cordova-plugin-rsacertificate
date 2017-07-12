var exec = require('cordova/exec');

exports.updateCertificate = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'updateCertificate', []);
};

exports.decryptFile = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'decryptFile', []);
};

