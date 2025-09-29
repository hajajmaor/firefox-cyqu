# How to Check PQ Settings in Firefox

## Method 1: Using about:config (GUI) ⭐ Easiest

1. **Open Firefox** (should already be running)
   ```bash
   cd /home/kono/projects/cyqu/firefox-cyqu
   ./mach run
   ```

2. **Navigate to about:config**
   - Type in address bar: `about:config`
   - Click "Accept the Risk and Continue"

3. **Search for PQ preferences**
   - In the search box, type: `security.pq`
   - You should see **3 new preferences**:

   ```
   security.pq.prefer_alt_sig         boolean    true
   security.pq.require_alt_sig        boolean    false  
   security.pq.show_ui_indicator      boolean    true
   ```

4. **What they mean**:
   - `prefer_alt_sig`: Enable PQ verification (default: on)
   - `require_alt_sig`: Fail connections without PQ sigs (default: off - graceful)
   - `show_ui_indicator`: Show "PQ" badge in UI (default: on)

---

## Method 2: Using Browser Console (DevTools) 🛠️

1. **Open DevTools Console**
   - Press `F12` or `Ctrl+Shift+K`
   - Click "Console" tab

2. **Run these commands**:

```javascript
// Check if PQ preferences exist
Services.prefs.getBoolPref("security.pq.prefer_alt_sig");
// Expected: true ✅

Services.prefs.getBoolPref("security.pq.require_alt_sig");
// Expected: false ✅

Services.prefs.getBoolPref("security.pq.show_ui_indicator");
// Expected: true ✅
```

3. **Test modifying a preference**:

```javascript
// Temporarily disable PQ verification
Services.prefs.setBoolPref("security.pq.prefer_alt_sig", false);

// Check it changed
Services.prefs.getBoolPref("security.pq.prefer_alt_sig");
// Returns: false

// Re-enable it
Services.prefs.setBoolPref("security.pq.prefer_alt_sig", true);
```

---

## Method 3: Check Source File Directly 📄

**View the preferences file**:

```bash
cd /home/kono/projects/cyqu/firefox-cyqu
grep -A5 "Post-Quantum" modules/libpref/init/all.js
```

**You should see**:

```javascript
// Post-Quantum Cryptography (PQC) hybrid signature preferences
// When true, prefer and display PQ signature verification status
pref("security.pq.prefer_alt_sig", true);
// When true, fail connections that don't have valid PQ signatures
// (default false - classical signature is authoritative)
pref("security.pq.require_alt_sig", false);
// Show PQ protection indicator in browser UI
pref("security.pq.show_ui_indicator", true);
```

---

## Verification Checklist ✅

- [ ] Firefox launches successfully
- [ ] `about:config` shows 3 `security.pq.*` preferences
- [ ] All preferences have correct default values
- [ ] Console commands return expected values
- [ ] Can modify preferences via console

---

## What Each Setting Does

### `security.pq.prefer_alt_sig` (default: true)
- **Enabled**: Verify ML-DSA signatures when present
- **Disabled**: Skip PQ verification, classical only
- **Use case**: Testing, debugging, performance comparison

### `security.pq.require_alt_sig` (default: false) ⚠️ CAUTION
- **Enabled**: FAIL connection if PQ signature missing/invalid
- **Disabled**: Allow connections, PQ is informational only
- **Use case**: Strict PQ-only environments (experimental!)
- **Warning**: Most sites don't have PQ sigs yet - this breaks browsing!

### `security.pq.show_ui_indicator` (default: true)
- **Enabled**: Show "PQ" badge/status in browser UI
- **Disabled**: Hide PQ status (still verifies if prefer_alt_sig=true)
- **Use case**: Clean UI, presentations
- **Note**: UI not implemented yet (Step 8), but preference is ready

---

## Advanced: Check in C++ Code

If you want to access these preferences from NSS/Firefox C++ code:

```cpp
// In Firefox chrome code:
nsCOMPtr<nsIPrefBranch> prefs = do_GetService(NS_PREFSERVICE_CONTRACTID);
bool preferAltSig = false;
prefs->GetBoolPref("security.pq.prefer_alt_sig", &preferAltSig);

if (preferAltSig) {
    // Perform PQ verification
}
```

---

## Troubleshooting

### Preferences don't show up in about:config
**Cause**: Firefox using old profile or preferences not loaded  
**Fix**:security.pq
```bash
# Create fresh profile
./mach run -P
# Create new profile, launch Firefox

# Or reset preferences
rm -rf obj-x86_64-pc-linux-gnu/tmp/profile-default
./mach run
```

### Console commands fail with "Services is not defined"
**Cause**: Wrong context (content page instead of browser)  
**Fix**: Open Browser Console instead:
- Menu → More Tools → Browser Console
- Or: `Ctrl+Shift+J`

### Preferences show but values won't change
**Cause**: Preferences might be locked by policy  
**Fix**: Check for `all.js` duplicates:
```bash
grep -r "security.pq" modules/libpref/
```

---

## Next: Test PQ Features

Once you've verified the preferences exist, you can:

1. **Install liboqs** to enable real ML-DSA verification
2. **Generate test certificates** with hybrid signatures
3. **Implement UI** to show PQ status badge
4. **Write tests** for the PQ verification logic

See `WHATS_NEXT.md` for detailed next steps!

---

**Quick Commands Summary**:

```bash
# Run Firefox
cd /home/kono/projects/cyqu/firefox-cyqu && ./mach run

# Then in Firefox:
# 1. Type in address bar: about:config
# 2. Search: security.pq
# 3. See your 3 new preferences! ✅
```
