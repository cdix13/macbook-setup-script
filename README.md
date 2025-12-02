# 🍎 MacBook Setup Script

A comprehensive, interactive bash script for setting up a new MacBook with Apple Silicon (ARM64) architecture. This script automates the installation and configuration of development tools, languages, applications, and macOS system tweaks.

## ✨ Features

### System & Core Tools

- ✅ **Xcode Command Line Tools** - Essential for development
- ✅ **Homebrew** - macOS package manager with auto PATH setup
- ✅ **Git Configuration** - Pre-configured with sensible defaults
- ✅ **Core Utilities** - `wget`, `jq`, `tree`, `htop`, `ripgrep`, `fd`, `tmux`, `fzf`, `zoxide`

### Shell & Terminal

- ✅ **Oh My Zsh** - Popular Zsh framework with plugins
- ✅ **Powerlevel10k** - Beautiful, blazing fast Zsh theme
- ✅ **Zsh Plugins** - Autosuggestions, syntax highlighting, and more
- ✅ **Custom Aliases** - Git, ls, navigation shortcuts
- ✅ **Shell Integration** - FZF, zoxide for fuzzy search and smart navigation

### Programming Languages

- ✅ **Python** - Latest version via pyenv with global default
- ✅ **Node.js** - LTS version via NVM with npm & yarn
- ✅ **Ruby** - Latest version via rbenv with bundler

### Development & Tools

- ✅ **Docker Desktop** - Containerization platform
- ✅ **NeoVim** - Modern terminal editor

### Applications

- ✅ **Browsers** - Google Chrome, Brave Browser
- ✅ **Editors** - Visual Studio Code
- ✅ **Terminal** - iTerm2
- ✅ **Productivity** - Raycast, Notion, Spotify
- ✅ **Utilities** - Rectangle (window manager)

### System Tweaks

- ✅ **Finder Enhancements** - Show hidden files, path bar, status bar
- ✅ **Trackpad** - Three-finger drag enabled
- ✅ **Keyboard** - Faster repeat rate, disable auto-capitalization
- ✅ **Battery** - Show percentage in menu bar

### Security

- ✅ **SSH Key Generation** - ED25519 key with keychain integration
- ✅ **SSH Config** - Auto-configured for GitHub/GitLab

## 🚀 Quick Start

### Prerequisites

- **Apple Silicon Mac** (M1, M2, M3, etc.) - This script is ARM64-only
- **Internet connection**
- **Administrator access**

### Installation

```bash
# Clone or download the script
cd /path/to/script

# Make it executable
chmod +x setup-mac.sh

# Run the script
./setup-mac.sh
```

## 📋 Usage

The script presents an interactive menu with the following options:

```
╔════════════════════════════════════╗
║   MACBOOK SETUP - INTERACTIVE      ║
╚════════════════════════════════════╝

 1) 🚀 Full setup (recommended)
 2) 🔧 Core system only (Xcode + Brew + Zsh)
 3) 🛠️  Dev tools only
 4) 🐍 Python only
 5) 📦 Node only
 6) 💎 Ruby only
 7) 📱 Apps only
 8) 🐳 Docker only
 9) ⚙️  Apply macOS Tweaks
10) 🧹 Cleanup Homebrew
11) ❌ Exit
```

### Option Details

| Option | What It Installs                                                    |
| ------ | ------------------------------------------------------------------- |
| **1**  | Everything (full setup) - Recommended for new Macs                  |
| **2**  | Xcode, Homebrew, Zsh with Oh My Zsh + Powerlevel10k                 |
| **3**  | Git, wget, jq, tree, htop, ripgrep, fd, neovim, tmux, fzf, zoxide   |
| **4**  | pyenv and latest Python version                                     |
| **5**  | NVM, Node.js LTS, and Yarn                                          |
| **6**  | rbenv, latest Ruby, and bundler                                     |
| **7**  | Chrome, Brave, VS Code, iTerm2, Raycast, Notion, Rectangle, Spotify |
| **8**  | Docker Desktop                                                      |
| **9**  | macOS system preferences and tweaks                                 |
| **10** | Clean up Homebrew cache and unused packages                         |
| **11** | Exit the script                                                     |

## 🔧 Configuration Details

### Git Configuration

The script configures Git with:

- **User**: `sidik`
- **Email**: `sidiksaepudin13@gmail.com`
- **Default branch**: `main`
- **Pull strategy**: `rebase` (instead of merge)
- **Rerere**: Enabled (remembers conflict resolutions)

> 💡 **Tip**: Edit the script to customize these values before running.

### Zsh Setup

The script:

1. **Backs up** your existing `.zshrc` file with timestamp
2. **Installs** Oh My Zsh framework
3. **Adds plugins**: git, docker, kubectl, fzf, zoxide, extract
4. **Configures** Powerlevel10k theme
5. **Sources** Homebrew plugins (autosuggestions, syntax highlighting)
6. **Sets up** custom aliases and shell integrations

### Python Setup (pyenv)

- Finds and installs the latest Python version
- Sets it as global default
- Adds pyenv initialization to `.zshrc`

### Node.js Setup (NVM)

- Installs NVM (Node Version Manager)
- Installs Node.js LTS version
- Installs Yarn globally via npm

### Ruby Setup (rbenv)

- Installs rbenv and ruby-build
- Finds and installs the latest Ruby version
- Installs bundler globally
- Updates RubyGems

### SSH Key Generation

During full setup, the script prompts to generate an ED25519 SSH key:

- Creates `~/.ssh/id_ed25519` key pair
- Configures SSH config with keychain integration
- Copies public key to clipboard for easy pasting to GitHub/GitLab

## ⚠️ Important Notes

### Sudo Access

- The script requires sudo access for some operations
- You'll be prompted for your password if needed
- Sudo access is kept alive throughout execution to avoid multiple prompts

### Post-Installation

After running the script:

1. **Restart your terminal** or run:

   ```bash
   source ~/.zshrc
   ```

2. **Configure Powerlevel10k** (if first time):

   ```bash
   p10k configure
   ```

3. **Open Docker Desktop** manually to complete setup

4. **Add SSH key to GitHub/GitLab** (public key will be in clipboard)

5. **Customize Git config** (if you changed name/email):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### Backups

The script automatically:

- Backs up your `.zshrc` file before modifying it (timestamp included)
- Uses `set -euo pipefail` for error handling
- Provides warnings for non-fatal errors

## 🔍 Script Safety

The script includes several safety features:

```bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures
IFS=$'\n\t'        # Safe field separator
```

- **Checks** if you're on Apple Silicon (ARM64)
- **Verifies** tool installations before proceeding
- **Handles errors gracefully** with warnings for non-fatal issues
- **Never overwrites** existing files without backing up first

## 🎨 Output Colors

The script uses colored output for clarity:

- 🟦 **Blue** (`▶`) - Information/progress
- 🟩 **Green** (`✔`) - Success
- 🟨 **Yellow** (`⚠`) - Warnings
- 🟥 **Red** (`✘`) - Errors

## 📝 Customization

To customize the script for your needs:

1. **Edit Git configuration** (lines ~110-115)

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

2. **Modify Homebrew packages** (lines ~130-131)

   ```bash
   local tools=(git wget jq tree htop ripgrep fd neovim tmux fzf zoxide)
   ```

3. **Change application list** (lines ~455-465)

   ```bash
   local apps=(
     google-chrome
     brave-browser
     # Add or remove apps here
   )
   ```

4. **Adjust Zsh plugins** (line ~160)
   ```bash
   plugins=(git docker kubectl fzf zoxide extract)
   ```

## 🐛 Troubleshooting

### Script Won't Run

```bash
# Make sure it's executable
chmod +x setup-mac.sh

# Run with explicit zsh
zsh setup-mac.sh
```

### "This script is for Apple Silicon only"

This script only works on Macs with Apple Silicon (M1, M2, M3, etc.). For Intel Macs, you'll need to modify the architecture check.

### Xcode Installation Fails

- If prompted to complete Xcode installation in a dialog, do so and re-run the script
- Alternatively, install manually: `xcode-select --install`

### Permission Denied on SSH

After SSH key generation, verify permissions:

```bash
ls -la ~/.ssqqqqqqh/
# Should show: drwx------ 2 user staff
```

### Homebrew Issues

Try these fixes:

```bash
# Fix permissions
sudo chown -R $(whoami) /opt/homebrew

# Update Homebrew
brew update && brew upgrade

# Doctor check
brew doctor
```

### NVM/Node Not Found

After running the script:

```bash
source ~/.zshrc  # Reload shell configuration
nvm list         # Check installed versions
node --version   # Verify Node works
```

## 📚 Additional Resources

- [Homebrew Documentation](https://brew.sh)
- [Oh My Zsh](https://ohmyz.sh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [NVM (Node Version Manager)](https://github.com/nvm-sh/nvm)
- [pyenv](https://github.com/pyenv/pyenv)
- [rbenv](https://github.com/rbenv/rbenv)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)

## 🤝 Contributing

To improve this script:

1. Test changes thoroughly on Apple Silicon Mac
2. Update this README with any new features
3. Ensure backward compatibility where possible
4. Add proper error handling for new features

## 📄 License

This script is provided as-is for personal use. Feel free to modify and share.

## 👤 Author

Created by **sidik** (sidiksaepudin13@gmail.com)

---

**Happy coding! 🚀**
