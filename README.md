# UIX Install
> [!NOTE]
> One-line commands to install [UIX](https://github.com/unyt-org/uix) on your system.
> This will install [deno for UIX](https://github.com/unyt-org/deno) and [UIX CLI](https://github.com/unyt-org/uix).

## Install Latest Version

**With Shell:**

```sh
curl -fsSL https://unyt.land/install.sh | bash
```

**With PowerShell:**

```powershell
irm https://unyt.land/install.ps1 | iex
```

## Install Specific Version

**With Shell:**

```sh
curl -fsSL https://unyt.land/install.sh | bash -s 1.0.0
```

**With PowerShell:**

```powershell
$v="1.0.0"; irm https://unyt.land/install.ps1 | iex
```

## Install via Package Manager

**With [Homebrew](https://formulae.brew.sh/formula/deno):**

```sh
brew install deno
```

## Environment Variables

- `UIX_INSTALL` - The directory in which to install Deno. This defaults to
  `$HOME/.uix`. The executable is placed in `$UIX_INSTALL/bin`. One
  application of this is a system-wide installation:

  **With Shell (`/usr/local`):**

  ```sh
  curl -fsSL https://unyt.land/install.sh | sudo UIX_INSTALL=/usr/local bash
  ```

  **With PowerShell (`C:\Program Files\uix`):**

  ```powershell
  # Run as administrator:
  $env:UIX_INSTALL = "C:\Program Files\uix"
  irm https://unyt.land/install.ps1 | iex
  ```

## Compatibility

- The Shell installer can be used on Windows with [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about), [MSYS](https://www.msys2.org) or equivalent set of tools.
