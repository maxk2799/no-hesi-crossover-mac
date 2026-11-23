# No Hesi on a Mac with CrossOver

Unofficial notes on getting Assetto Corsa, Custom Shaders Patch (CSP) and No Hesi servers working on an Apple Silicon Mac **without the No Hesi launcher**.

Not affiliated with No Hesi, Kunos, CodeWeavers, the CSP authors or the Shutoko Revival Project. This repo contains no game files, mods or DLLs. You download everything from its own source.

## What this was tested on

One machine, late 2026:

| | |
|---|---|
| Mac | Apple Silicon, macOS 27 |
| CrossOver | 26.2, 64-bit Windows 10 bottle, DXVK, MSync |
| Assetto Corsa | 1.16.4 from Steam |
| CSP | 0.2.11 (build 3465) |
| Servers joined | No Hesi Nordschleife and SRP |

Other setups may behave differently. Long-session stability, wheels and force feedback are untested. One SRP load flashed black and crashed; a later load worked.

## Before you start

- Back up your bottle (CrossOver > Archive Bottle).
- Servers decide who can join. If a server rejects you, ask its owners. Nothing here gets around bans, anti-cheat, logins or paid tiers.
- The scripts change your bottle's registry and game folder. Read them first.

## Setup

### 1. Install the game
Install Steam and Assetto Corsa in a 64-bit Windows 10 bottle. Let Steam finish installing its DirectX redistributables. Close the game.

### 2. Install Content Manager
1. Download it from <https://assettocorsa.club/content-manager.html>.
2. Put it in the bottle at `C:\Content Manager\`.
3. Rename it to exactly `Content Manager Local Safe.exe`.

### 3. Install CSP 0.2.11
1. Download it from <https://acstuff.club/patch/>.
2. Extract `dwrite.dll` and `extension/` into the `assettocorsa` folder.

### 4. Get CrossOver 25.1.1 (only for one file)
CrossOver 26's `dbghelp.dll` left CSP unable to find 85 game functions ("Failed to patch Assetto Corsa"). The one from 25.1.1 fixed it. You do not need to run 25.1.1.

1. Download `crossover-25.1.1.zip` from CodeWeavers:
   <https://media.codeweavers.com/pub/crossover/cxmac/demo/crossover-25.1.1.zip>
2. Unzip it somewhere temporary and check its signature:
   ```bash
   codesign --verify --deep --strict /path/to/25.1.1/CrossOver.app
   ```

### 5. Run the setup script
Open CrossOver, keep Steam running in the bottle, and close the game and Content Manager.

```bash
./scripts/setup.sh --bottle Steam --crossover "/Applications/CrossOver.app" --crossover25 "/path/to/25.1.1/CrossOver.app"
```

It never overwrites existing files. It:

| Change | Why |
|---|---|
| Microsoft `d3dx11_43` and `d3dcompiler_43` from Steam's own DirectX folder | Built-in `d3dx11_43` crashed while loading a texture |
| `dbghelp.dll` from CrossOver 25.1.1, with its "builtin" marker blanked so Wine accepts it as native | Lets CSP patch the game |
| `dwrite` override | Loads CSP |
| Copies of your Mac's Arial as `segoeui*.ttf` in `content/fonts/system` | CSP stops if Segoe UI is missing |
| `CACHE_ACS=0` in CSP's `general.ini` | Cleared a cache error. Possibly not needed |
| WPF software drawing for the bottle | Content Manager's window went blank white |

DLL overrides apply to `acs.exe` only.

### 6. Test offline
Open Content Manager, leave motion blur off, and run Practice with a stock car. In `Documents/Assetto Corsa/logs/custom_shaders_patch.log` look for:

```
All 2375 functions were found successfully
```

### 7. Make browser join links work
No Hesi's site can use `acmanager://` links, which macOS cannot pass into CrossOver by itself. This builds a small helper app that only accepts online-join links:

```bash
./scripts/make-join-app.sh --bottle Steam --crossover "/Applications/CrossOver.app"
```

### 8. Get the cars
1. Open <https://nohesi.gg/servers> and click Quick Play.
2. Content Manager shows the server's address and what is missing.
3. If **Install missing content** works, use that. On the test machine it did not, apparently because Content Manager's 7-Zip plugin failed under CrossOver.

Otherwise list what the server asks for. This reads the server's public info and downloads nothing:

```bash
python3 scripts/list-server-content.py SERVER_IP:HTTP_PORT --cars "/path/to/assettocorsa/content/cars"
```

Download the cars you want from the official links it prints, look inside, and extract them into `content/cars`. macOS can open them:

```bash
bsdtar -tf car.7z
```

```bash
bsdtar -xkf car.7z -C "/path/to/assettocorsa/content/cars"
```

Some official cars include **obfuscated Lua scripts** that cannot be reviewed, probably copy protection. Decide for yourself whether to install them.

### 9. Get SRP
Download the stable 0.9.3 release from <https://shutokorevivalproject.com/#download> after reading its terms, then extract its `content` folder into `assettocorsa`. Do not modify or rehost it.

The Traffic V2 SRP server checked required CSP build 3465. Traffic V1 servers needed extra small traffic cars.

## Playing

1. Open Steam in CrossOver and wait for it to log in.
2. Open <https://nohesi.gg/servers> and click Quick Play.
3. Pick a free car in Content Manager and click **Join**, not Drive.

The first load can take several minutes. Close other large apps, as SRP uses a lot of memory.

## Problems

| Problem | Try |
|---|---|
| "Failed to patch Assetto Corsa" | Check that the 25.1.1 `dbghelp.dll` and its override are still there |
| Game crashes loading a texture | Check the two DirectX DLLs and overrides |
| "Font segoeui.ttf is missing" | Run the setup script again |
| Content Manager is white | Restart it, and check the software drawing setting |
| `AcTools.CurrentlyPlaying.exe` error | Click Close. The race kept working |
| Car reset key does nothing online | CSP's reset is labeled offline only |
| Broke after an update | CrossOver and CSP updates can undo this |

## What did not work

- **No Hesi launcher:** WebView2 109 is too old for it, and version 158 started but showed a blank window. CrossOver also added `--no-sandbox` to WebView2, so avoid logging in through it.
- **Microsoft's `dbghelp.dll`** (from the NuGet debugging package): CSP found no symbols at all.

## Undo

Delete `dbghelp.dll`, `d3dx11_43.dll`, `d3dcompiler_43.dll`, `dwrite.dll`, `extension/` and the added `content/fonts/system/segoeui*.ttf` from the game folder, then run:

```bash
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle Steam reg delete 'HKCU\Software\Wine\AppDefaults\acs.exe\DllOverrides' /f
```

```bash
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle Steam reg delete 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /f
```
