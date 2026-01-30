import Foundation

class MUCertificateController: NSObject {
    class func certificate(withPersistentRef persistentRef: Data) -> MKCertificate? {
        let query: [String: Any] = [
            kSecValuePersistentRef as String: persistentRef,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let result = item else { return nil }

        if CFGetTypeID(result) == SecIdentityGetTypeID() {
            let identity = result as! SecIdentity
            var cert: SecCertificate?
            if SecIdentityCopyCertificate(identity, &cert) == errSecSuccess, let secCert = cert {
                let certData = SecCertificateCopyData(secCert) as Data
                var key: SecKey?
                if SecIdentityCopyPrivateKey(identity, &key) == errSecSuccess, let secKey = key {
                    let pkeyQuery: [String: Any] = [
                        kSecValueRef as String: secKey,
                        kSecReturnData as String: true,
                        kSecMatchLimit as String: kSecMatchLimitOne
                    ]
                    var keyData: CFTypeRef?
                    if SecItemCopyMatching(pkeyQuery as CFDictionary, &keyData) == errSecSuccess,
                       let data = keyData as? Data {
                        return MKCertificate(certificate: certData, privateKey: data)
                    }
                }
            }
        } else if CFGetTypeID(result) == SecCertificateGetTypeID() {
            let secCert = result as! SecCertificate
            let certData = SecCertificateCopyData(secCert) as Data
            return MKCertificate(certificate: certData, privateKey: nil)
        }
        return nil
    }

    class func deleteCertificate(withPersistentRef persistentRef: Data) -> OSStatus {
        let op = [kSecValuePersistentRef as String: persistentRef] as CFDictionary
        return SecItemDelete(op)
    }

    class func fingerprint(fromHexString hexDigest: String) -> String {
        var fingerprint = ""
        for (idx, ch) in hexDigest.enumerated() {
            if idx % 2 == 0 && idx > 0 && idx < hexDigest.count - 1 {
                fingerprint.append(":")
            }
            fingerprint.append(ch)
        }
        return fingerprint
    }

    class func setDefaultCertificate(byPersistentRef persistentRef: Data) {
        UserDefaults.standard.set(persistentRef, forKey: "DefaultCertificate")
    }

    class func defaultCertificate() -> MKCertificate? {
        guard let ref = UserDefaults.standard.data(forKey: "DefaultCertificate") else { return nil }
        return certificate(withPersistentRef: ref)
    }

    class func persistentRefsForIdentities() -> [Data]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnPersistentRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var array: CFTypeRef?
        let err = SecItemCopyMatching(query as CFDictionary, &array)
        guard err == errSecSuccess else { return nil }
        return array as? [Data]
    }
}

