/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#pragma once

#include "mozilla/Vector.h"
#include "certt.h"  // CERTCertificate

namespace mozilla {
namespace psm {

enum class AltSigStatus { NotPresent, Verified, Failed, Unknown };

// Verifies Dilithium-3 alternative signature on the given leaf certificate.
// This is a stub implementation - full verification requires liboqs integration.
// TODO: Parse X.509 alt-sig extension (OID + blob), extract Dil-3 public key
//       and signature, compute over TBSCertificate, verify with liboqs.
AltSigStatus VerifyAltSigDilithium3(CERTCertificate* leaf,
                                    const mozilla::Vector<CERTCertificate*>& chain);

}  // namespace psm
}  // namespace mozilla


