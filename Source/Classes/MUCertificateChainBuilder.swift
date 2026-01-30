import Foundation

fileprivate func findValidParents(for cert: SecCertificate) -> [SecCertificate]? {
    guard let attrs = getAttrs(for: cert),
          let issuer = attrs[kSecAttrIssuer as String] as? Data else { return nil }
    let query: [String: Any] = [
        kSecClass as String: kSecClassCertificate,
        kSecAttrSubject as String: issuer,
        kSecReturnAttributes as String: true,
        kSecReturnRef as String: true,
        kSecMatchLimit as String: kSecMatchLimitAll
    ]
    var allAttrs: CFTypeRef?
    let err = SecItemCopyMatching(query as CFDictionary, &allAttrs)
    guard err == errSecSuccess, let attrsArray = allAttrs as? [[String: Any]] else { return nil }

    var validParents: [SecCertificate] = []
    for parentAttr in attrsArray {
        guard let parentRef = parentAttr[kSecValueRef as String] else { continue }
        // SecCertificate is a CoreFoundation type - use unsafeBitCast
        let parentCert = unsafeBitCast(parentRef, to: SecCertificate.self)
        let parentData = SecCertificateCopyData(parentCert) as Data
        let childData = SecCertificateCopyData(cert) as Data
        guard let parent = MKCertificate(certificate: parentData, privateKey: nil),
              let child = MKCertificate(certificate: childData, privateKey: nil) else { continue }
        if parent.isValid(on: Date()) && child.isSigned(by: parent) {
            validParents.append(parentCert)
        }
    }
    return validParents.isEmpty ? nil : validParents
}

fileprivate func getAttrs(for cert: SecCertificate) -> [String: Any]? {
    let query: [String: Any] = [
        kSecValueRef as String: cert,
        kSecReturnRef as String: true,
        kSecReturnAttributes as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var attrs: CFTypeRef?
    let err = SecItemCopyMatching(query as CFDictionary, &attrs)
    guard err == errSecSuccess else { return nil }
    return attrs as? [String: Any]
}

fileprivate func certIsSelfSignedAndValid(_ cert: SecCertificate) -> Bool {
    guard let attrs = getAttrs(for: cert),
          let subject = attrs[kSecAttrSubject as String] as? Data,
          let issuer = attrs[kSecAttrIssuer as String] as? Data,
          subject == issuer else { return false }
    let data = SecCertificateCopyData(cert) as Data
    guard let selfSigned = MKCertificate(certificate: data, privateKey: nil) else { return false }
    return selfSigned.isValid(on: Date()) && selfSigned.isSigned(by: selfSigned)
}

fileprivate func buildCertChain(from cert: SecCertificate) -> [SecCertificate]? {
    var ignored: Bool = false
    return buildCertChain(from: cert, isFullChain: &ignored)
}

fileprivate func buildCertChain(from cert: SecCertificate, isFullChain: inout Bool) -> [SecCertificate]? {
    if certIsSelfSignedAndValid(cert) {
        isFullChain = true
        return nil
    } else {
        isFullChain = false
    }

    guard let parents = findValidParents(for: cert) else { return nil }
    for parent in parents {
        var full = false
        let allParents = buildCertChain(from: parent, isFullChain: &full)
        isFullChain = full
        if full && allParents == nil {
            return [parent]
        } else if full, let chain = allParents {
            return [parent] + chain
        }
    }
    return nil
}

class MUCertificateChainBuilder: NSObject {
    class func buildChain(fromPersistentRef persistentRef: Data) -> [Any]? {
        var thing: CFTypeRef?
        let query: [String: Any] = [
            kSecValuePersistentRef as String: persistentRef,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        guard SecItemCopyMatching(query as CFDictionary, &thing) == errSecSuccess,
              let result = thing else { return nil }
        var chain: [Any] = []
        if CFGetTypeID(result) == SecIdentityGetTypeID() {
            let identity = result as! SecIdentity
            chain.append(identity)
            var cert: SecCertificate?
            SecIdentityCopyCertificate(identity, &cert)
            if let c = cert {
                if let parents = buildCertChain(from: c) {
                    chain.append(contentsOf: parents)
                }
            }
        } else if CFGetTypeID(result) == SecCertificateGetTypeID() {
            let cert = result as! SecCertificate
            chain.append(cert)
            if let parents = buildCertChain(from: cert) {
                chain.append(contentsOf: parents)
            }
        }
        return chain
    }
}

