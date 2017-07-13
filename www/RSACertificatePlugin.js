var exec = require('cordova/exec');

exports.updateCertificate = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'updateCertificate', []);
};

exports.decryptFile = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'decryptFile', []);
};

exports.deleteCertificate = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'deleteCertificate', []);
};

exports.deleteDataFiles = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'deleteDataFiles', []);
};

exports.cleanup = function(success, error) {
    exec(success, error, 'RSACertificatePlugin', 'cleanup', []);
};
