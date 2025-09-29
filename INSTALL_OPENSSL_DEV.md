# 🔧 Install OpenSSL Development Libraries

## **Issue**: OpenSSL headers not found

liboqs needs OpenSSL development headers to build.

## **Quick Fix** (30 seconds):

```bash
sudo apt-get install -y libssl-dev
```

Then run the installation again:

```bash
sudo ./install_liboqs.sh && ./mach build
```

---

## **Complete Command** (Copy-paste this):

```bash
sudo apt-get install -y libssl-dev && sudo ./install_liboqs.sh && ./mach build
```

**What this does**:
1. ✅ Install OpenSSL dev headers (30 sec)
2. ✅ Build & install liboqs (3 min)
3. ✅ Build Firefox with PQ support (20 min)

**Total time**: ~23 minutes

---

## **Progress So Far**

- ✅ cmake installed
- ✅ build-essential installed
- ⏳ OpenSSL dev headers (run command above)
- ⏳ liboqs build (automatic)
- ⏳ Firefox build (automatic)

---

**Copy the command above and you're done!** 🚀
