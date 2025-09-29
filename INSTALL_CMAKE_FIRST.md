# 🔧 Install cmake First

## **Issue**: cmake not found

You need to install cmake before building liboqs.

## **Quick Fix** (1 minute):

```bash
sudo apt-get update && sudo apt-get install -y cmake build-essential
```

Then run the installation again:

```bash
sudo ./install_liboqs.sh && ./mach build
```

---

## **What's Happening**

1. ✅ You ran `sudo ./install_liboqs.sh` (good!)
2. ❌ cmake is missing (need to install)
3. ⏳ After cmake installed, script will work

---

## **Complete Command Sequence**

```bash
# Step 1: Install cmake
sudo apt-get update
sudo apt-get install -y cmake build-essential

# Step 2: Install liboqs and build Firefox
sudo ./install_liboqs.sh && ./mach build
```

**Estimated time**: 25 minutes total
- cmake install: 2 min
- liboqs build: 3 min  
- Firefox build: 20 min

---

**Run the commands above and you're done!** 🚀
