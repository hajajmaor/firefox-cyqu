/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 * Post-quantum hybrid certificate verification
 * 
 * This implements alternative signature verification for hybrid PQC certificates.
 * Certificates can carry both a classical signature (RSA/ECDSA) and a post-quantum
 * signature (ML-DSA/Dilithium) in X.509v3 extensions 2.5.29.73 and 2.5.29.74.
 * 
 * Refs: EJBCA Hybrid Signatures, IETF LAMPS draft, FIPS-204
 */

#include "cert.h"
#include "secoid.h"
#include "secerr.h"
#include "blapi.h"
#include "ml_dsat.h"

/*
 * Verify the alternative (PQ) signature on a certificate
 * 
 * @param cert The certificate whose alt-sig to verify
 * @param issuerCert The issuer's certificate (contains PQ public key)
 * @return SECSuccess if alt-sig verifies, SECFailure otherwise
 */
SECStatus
CERT_VerifyAltSignature(CERTCertificate *cert, CERTCertificate *issuerCert)
{
    SECOidTag altSigAlg;
    SECItem *altSigPubKey = NULL;
    SECStatus rv;
    
    if (!cert || !issuerCert) {
        PORT_SetError(SEC_ERROR_INVALID_ARGS);
        return SECFailure;
    }
    
    /* Check if certificate has alternative signature */
    if (!cert->hasAltSignature) {
        PORT_SetError(SEC_ERROR_EXTENSION_NOT_FOUND);
        return SECFailure;
    }
    
    /* Check if alt-sig algorithm is supported (ML-DSA) */
    altSigAlg = SECOID_GetAlgorithmTag(cert->altSignatureAlgorithm);
    
    if (altSigAlg != SEC_OID_ML_DSA_44 &&
        altSigAlg != SEC_OID_ML_DSA_65 &&
        altSigAlg != SEC_OID_ML_DSA_87) {
        PORT_SetError(SEC_ERROR_UNSUPPORTED_KEYALG);
        return SECFailure;
    }
    
    /* 
     * Extract ML-DSA public key from issuer certificate
     * TODO: This needs proper handling - ML-DSA public key might be:
     *  1. In the standard subjectPublicKeyInfo (for pure ML-DSA certs)
     *  2. In a separate extension (for hybrid certs)
     *  3. Embedded in composite key structure
     * 
     * For now, we assume it's in subjectPublicKeyInfo with ML-DSA OID
     */
    if (SECOID_GetAlgorithmTag(&issuerCert->subjectPublicKeyInfo.algorithm) == altSigAlg) {
        /* Issuer uses same ML-DSA algorithm, extract public key */
        altSigPubKey = &issuerCert->subjectPublicKeyInfo.subjectPublicKey;
    } else {
        /* TODO: Handle hybrid/composite keys or alternative public key locations */
        PORT_SetError(SEC_ERROR_BAD_KEY);
        return SECFailure;
    }
    
    if (!altSigPubKey || !altSigPubKey->data) {
        PORT_SetError(SEC_ERROR_BAD_KEY);
        return SECFailure;
    }
    
    /*
     * Verify the ML-DSA signature over the TBS (To-Be-Signed) certificate bytes
     * The same TBS bytes are used for both classical and PQ signatures
     */
    rv = MLDSA_Verify(
        altSigPubKey->data, altSigPubKey->len,
        cert->signatureWrap.data.data, cert->signatureWrap.data.len,
        cert->altSignatureValue.data, cert->altSignatureValue.len,
        NULL, 0  /* No context string */
    );
    
    return rv;
}

/*
 * Verify alternative signature on entire certificate chain
 * 
 * This checks that:
 * 1. Every cert in the chain has alt-sig extensions
 * 2. Every alt-sig verifies successfully  
 * 3. All use compatible PQ algorithms
 * 
 * @param certList The certificate chain to verify
 * @return SECSuccess only if ALL certs have valid alt-sigs
 */
SECStatus
CERT_VerifyAltSignatureChain(CERTCertList *certList)
{
    CERTCertListNode *node;
    CERTCertificate *cert, *issuer;
    SECStatus rv;
    PRBool allHaveAltSig = PR_TRUE;
    PRBool allAltSigValid = PR_TRUE;
    
    if (!certList) {
        PORT_SetError(SEC_ERROR_INVALID_ARGS);
        return SECFailure;
    }
    
    /* Iterate through chain (leaf to root) */
    for (node = CERT_LIST_HEAD(certList);
         !CERT_LIST_END(node, certList);
         node = CERT_LIST_NEXT(node)) {
        
        cert = node->cert;
        
        /* Check if cert has alt-sig */
        if (!cert->hasAltSignature) {
            allHaveAltSig = PR_FALSE;
            break;
        }
        
        /* Get issuer (next cert in chain, or self for root) */
        if (CERT_LIST_END(CERT_LIST_NEXT(node), certList)) {
            /* Root cert - verify with its own key (self-signed) */
            issuer = cert;
        } else {
            issuer = CERT_LIST_NEXT(node)->cert;
        }
        
        /* Verify alt-sig */
        rv = CERT_VerifyAltSignature(cert, issuer);
        if (rv != SECSuccess) {
            allAltSigValid = PR_FALSE;
            break;
        }
    }
    
    /* 
     * Policy: Only mark "PQ" if ALL certs have alt-sig AND all verify successfully
     * Otherwise: mark "Not PQ" (but connection still succeeds - classical sig is authoritative)
     */
    if (allHaveAltSig && allAltSigValid) {
        return SECSuccess;  /* Chain is fully PQ-protected */
    } else {
        /* Chain is not fully PQ - classical only or verification failed */
        if (!allHaveAltSig) {
            PORT_SetError(SEC_ERROR_EXTENSION_NOT_FOUND);
        }
        return SECFailure;
    }
}

/*
 * Get PQ verification status for a certificate chain
 * Returns a human-readable string describing the PQ status
 */
const char *
CERT_GetPQVerificationStatus(CERTCertList *certList, PRBool *isPQProtected)
{
    SECStatus rv = CERT_VerifyAltSignatureChain(certList);
    
    if (rv == SECSuccess) {
        if (isPQProtected) *isPQProtected = PR_TRUE;
        return "PQ: All certificates verified with ML-DSA";
    } else {
        if (isPQProtected) *isPQProtected = PR_FALSE;
        
        PRErrorCode err = PORT_GetError();
        if (err == SEC_ERROR_EXTENSION_NOT_FOUND) {
            return "Not PQ: Missing alternative signature on one or more certificates";
        } else if (err == SEC_ERROR_BAD_SIGNATURE) {
            return "Not PQ: Alternative signature verification failed";
        } else if (err == SEC_ERROR_UNSUPPORTED_KEYALG) {
            return "Not PQ: Unsupported alternative signature algorithm";
        } else {
            return "Not PQ: Alternative signature verification error";
        }
    }
}
