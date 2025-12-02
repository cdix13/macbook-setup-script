#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# =============================
# COLORS & HELPERS
# =============================
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

log() { echo "${BLUE}▶ $1${NC}"; }
success() { echo "${GREEN}✔ $1${NC}"; }
warn() { echo "${YELLOW}⚠ $1${NC}"; }
error() { echo "${RED}✘ $1${NC}"; }

# =============================
# SYSTEM CHECK
# =============================
ensure_arm64() {
  if [[ "$(uname -m)" != "arm64" ]]; then
    error "This script is for Apple Silicon only."
    exit 1
  fi
}

check_sudo() {
  log "Checking sudo access..."
  if sudo -n true 2>/dev/null; then
    success "Sudo access confirmed"
  else
    warn "This script may need sudo access for some operations."
    warn "You might be prompted for your password."
    sudo -v
    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  fi
}

# =============================
# XCODE CLI
# =============================
install_xcode() {
  log "Checking Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    log "Installing Xcode Command Line Tools..."
    xcode-select --install
    warn "Please complete the Xcode installation in the dialog, then re-run this script."
    exit 0
  else
    success "Xcode CLI already installed"
  fi
}

# =============================
# HOMEBREW
# =============================
install_brew() {
  log "Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    # Add to shell profile if not already there
    if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    
    success "Homebrew installed"
  else
    success "Homebrew already installed"
  fi

  log "Updating Homebrew..."
  brew update 2>/dev/null || warn "Brew update had issues (non-fatal)"
  brew upgrade 2>/dev/null || warn "Brew upgrade had issues (non-fatal)"
}

# =============================
# DEV ESSENTIALS + GIT CONFIG
# =============================
install_dev_tools() {
  log "Installing Dev Essentials..."
  
  local tools=(git wget jq tree htop ripgrep fd neovim tmux fzf zoxide)
  for tool in "${tools[@]}"; do
    if ! brew list "$tool" &>/dev/null; then
      brew install "$tool" || warn "Failed to install $tool"
    fi
  done

  # FZF shell integration
  if [[ -f "/opt/homebrew/opt/fzf/install" ]]; then
    /opt/homebrew/opt/fzf/install --all --no-bash --no-fish 2>/dev/null || true
  fi

  log "Configuring Git..."
  git config --global user.name "sidik" 2>/dev/null || true
  git config --global user.email "sidiksaepudin13@gmail.com" 2>/dev/null || true
  git config --global init.defaultBranch main 2>/dev/null || true
  git config --global pull.rebase true 2>/dev/null || true
  git config --global rerere.enabled true 2>/dev/null || true
  git config --global core.editor nano 2>/dev/null || true

  success "Dev tools & Git configured"
}

# =============================
# OH MY ZSH + PLUGINS + P10K
# =============================
setup_zsh() {
  log "Setting up Zsh environment..."
  
  # Backup existing .zshrc
  if [[ -f ~/.zshrc ]]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
  fi

  # Install Oh My Zsh
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        warn "Oh My Zsh installation had issues"
        return 1
      }
  else
    success "Oh My Zsh already installed"
  fi

  # Install Zsh plugins and Powerlevel10k
  log "Installing Zsh plugins + Powerlevel10k..."
  local zsh_packages=(zsh-autosuggestions zsh-syntax-highlighting powerlevel10k)
  for package in "${zsh_packages[@]}"; do
    if ! brew list "$package" &>/dev/null; then
      brew install "$package" || warn "Failed to install $package"
    fi
  done

  # Configure .zshrc
  configure_zshrc

  success "Zsh + Powerlevel10k configured"
}

configure_zshrc() {
  local zshrc="$HOME/.zshrc"
  
  # Remove old theme line
  if grep -q "^ZSH_THEME=" "$zshrc" 2>/dev/null; then
    sed -i.bak '/^ZSH_THEME=/d' "$zshrc"
  fi
  
  # Add new theme at the top (before Oh My Zsh sources)
  if ! grep -q "ZSH_THEME=\"robbyrussell\"" "$zshrc" 2>/dev/null; then
    # Find the line with 'export ZSH=' and add theme after it
    if grep -q "^export ZSH=" "$zshrc" 2>/dev/null; then
      sed -i.bak '/^export ZSH=/a\
ZSH_THEME="robbyrussell"
' "$zshrc"
    fi
  fi

  # Update plugins - only use built-in Oh My Zsh plugins
  if grep -q "^plugins=" "$zshrc" 2>/dev/null; then
    sed -i.bak 's|^plugins=.*|plugins=(git docker kubectl fzf zoxide extract)|' "$zshrc"
  else
    echo 'plugins=(git docker kubectl fzf zoxide extract)' >> "$zshrc"
  fi

  # Add aliases and inits if not present
  if ! grep -q "alias g=" "$zshrc" 2>/dev/null; then
    cat >> "$zshrc" << 'EOF'

# Custom aliases
alias g="git"
alias ll="ls -lah"
alias ..="cd .."
alias ...="cd ../.."

EOF
  fi

  # Homebrew
  if ! grep -q "brew shellenv" "$zshrc" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$zshrc"
  fi

  # Zoxide
  if ! grep -q "zoxide init" "$zshrc" 2>/dev/null; then
    echo 'eval "$(zoxide init zsh)"' >> "$zshrc"
  fi

  # Source Homebrew-installed plugins (must be after Oh My Zsh initialization)
  if ! grep -q "# Homebrew Zsh plugins" "$zshrc" 2>/dev/null; then
    cat >> "$zshrc" << 'EOF'

# Homebrew Zsh plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
  fi
  
  # Add Powerlevel10k at the very end (must be after Oh My Zsh)
  if ! grep -q "powerlevel10k.zsh-theme" "$zshrc" 2>/dev/null; then
    cat >> "$zshrc" << 'EOF'

# Powerlevel10k theme
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
EOF
  fi
  
  # Create p10k config if it doesn't exist
  if [[ ! -f "$HOME/.p10k.zsh" ]]; then
    warn "Run 'p10k configure' after restart to set up Powerlevel10k"
  fi
}

# =============================
# PYENV + PYTHON
# =============================
install_python() {
  log "Installing pyenv + latest Python..."
  
  if ! brew list pyenv &>/dev/null; then
    brew install pyenv || return 1
  fi

  # Add pyenv to .zshrc
  if ! grep -q 'pyenv init' ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
  fi

  # Initialize pyenv for current session
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)" 2>/dev/null || true
  eval "$(pyenv init -)" 2>/dev/null || true

  # Install latest Python
  log "Finding and installing latest Python version..."
  LATEST_PYTHON=$(pyenv install --list 2>/dev/null | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
  
  if [[ -n "$LATEST_PYTHON" ]]; then
    pyenv install -s "$LATEST_PYTHON" || warn "Python installation had issues"
    pyenv global "$LATEST_PYTHON" || warn "Could not set global Python version"
    success "Python $LATEST_PYTHON installed globally"
  else
    warn "Could not determine latest Python version"
  fi
}

# =============================
# NVM + NODE + YARN
# =============================
install_node() {
  log "Installing NVM + Node LTS..."
  
  if ! brew list nvm &>/dev/null; then
    brew install nvm || return 1
  fi
  
  mkdir -p ~/.nvm

  # Add NVM to .zshrc
  if ! grep -q 'NVM_DIR' ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
EOF
  fi

  # Initialize NVM for current session
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

  # Install Node LTS
  nvm install --lts || warn "Node installation had issues"
  nvm use --lts || true
  
  # Install Yarn
  if command -v npm &>/dev/null; then
    npm install -g yarn || warn "Yarn installation had issues"
  fi

  success "Node LTS + Yarn installed"
}

# =============================
# RBENV + RUBY
# =============================
install_ruby() {
  log "Installing rbenv + latest Ruby..."
  
  local ruby_packages=(rbenv ruby-build)
  for package in "${ruby_packages[@]}"; do
    if ! brew list "$package" &>/dev/null; then
      brew install "$package" || warn "Failed to install $package"
    fi
  done

  # Add rbenv to .zshrc
  if ! grep -q 'rbenv init' ~/.zshrc 2>/dev/null; then
    echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
  fi

  # Initialize rbenv for current session
  eval "$(rbenv init - zsh)" 2>/dev/null || true

  # Install latest Ruby
  log "Finding and installing latest Ruby version..."
  LATEST_RUBY=$(rbenv install -l 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
  
  if [[ -n "$LATEST_RUBY" ]]; then
    rbenv install -s "$LATEST_RUBY" || warn "Ruby installation had issues"
    rbenv global "$LATEST_RUBY" || warn "Could not set global Ruby version"
    
    # Update RubyGems and install Bundler
    gem update --system 2>/dev/null || warn "RubyGems update had issues"
    gem install bundler 2>/dev/null || warn "Bundler installation had issues"
    
    success "Ruby $LATEST_RUBY installed"
  else
    warn "Could not determine latest Ruby version"
  fi
}

# =============================
# DOCKER DESKTOP
# =============================
install_docker() {
  log "Installing Docker Desktop..."
  
  if ! brew list --cask docker &>/dev/null; then
    brew install --cask docker || warn "Docker Desktop installation had issues"
    success "Docker Desktop installed"
    warn "You'll need to open Docker Desktop manually to complete setup"
  else
    success "Docker Desktop already installed"
  fi
}

# =============================
# APPS
# =============================
install_apps() {
  log "Installing Applications..."
  
  local apps=(
    google-chrome
    brave-browser
    visual-studio-code
    iterm2
    raycast
    notion
    rectangle
    spotify
  )
  
  for app in "${apps[@]}"; do
    if ! brew list --cask "$app" &>/dev/null; then
      log "Installing $app..."
      brew install --cask "$app" || warn "Failed to install $app"
    fi
  done

  success "Apps installed"
}

# =============================
# MACOS TWEAKS
# =============================
apply_macos_tweaks() {
  log "Applying macOS tweaks..."

  # Finder tweaks
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  # Trackpad: three-finger drag
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false

  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Show battery percentage
  defaults write com.apple.menuextra.battery ShowPercent -bool true

  # Disable automatic capitalization
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

  # Disable automatic period substitution
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

  # Restart affected applications
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true

  success "macOS tweaks applied"
}

# =============================
# SSH KEY GENERATION
# =============================
ssh_prompt() {
  echo ""
  echo -n "Generate SSH key now? (y/n): "
  read -r SSH_CONFIRM

  if [[ "$SSH_CONFIRM" == "y" || "$SSH_CONFIRM" == "Y" ]]; then
    KEY_PATH="$HOME/.ssh/id_ed25519"

    if [[ -f "$KEY_PATH" ]]; then
      warn "SSH key already exists: $KEY_PATH"
      echo -n "View public key? (y/n): "
      read -r VIEW_KEY
      if [[ "$VIEW_KEY" == "y" || "$VIEW_KEY" == "Y" ]]; then
        cat "$KEY_PATH.pub"
        pbcopy < "$KEY_PATH.pub" 2>/dev/null && success "Public key copied to clipboard"
      fi
    else
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      
      ssh-keygen -t ed25519 -C "sidiksaepudin13@gmail.com" -f "$KEY_PATH" -N ""
      
      eval "$(ssh-agent -s)" 2>/dev/null || true
      ssh-add "$KEY_PATH" 2>/dev/null || true
      
      # Add to SSH config
      if [[ ! -f "$HOME/.ssh/config" ]] || ! grep -q "id_ed25519" "$HOME/.ssh/config"; then
        cat >> "$HOME/.ssh/config" << EOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "$HOME/.ssh/config"
      fi
      
      pbcopy < "$KEY_PATH.pub" 2>/dev/null && success "SSH key generated and copied to clipboard"
      
      echo ""
      warn "Add this key to GitHub/GitLab:"
      cat "$KEY_PATH.pub"
    fi
  else
    warn "SSH key generation skipped"
  fi
}

# =============================
# CLEANUP
# =============================
cleanup() {
  log "Cleaning up..."
  brew cleanup 2>/dev/null || true
  success "Cleanup complete"
}

# =============================
# INTERACTIVE MENU
# =============================
print_menu() {
  cat << EOF

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

EOF
}

# =============================
# MAIN
# =============================
main() {
  ensure_arm64
  
  print_menu
  echo -n "Select an option (1-11): "
  read -r choice

  case $choice in
    1)
      check_sudo
      install_xcode
      install_brew
      setup_zsh
      install_dev_tools
      install_python
      install_node
      install_ruby
      install_docker
      install_apps
      apply_macos_tweaks
      cleanup
      ssh_prompt
      ;;
    2)
      check_sudo
      install_xcode
      install_brew
      setup_zsh
      ;;
    3)
      install_brew
      install_dev_tools
      ;;
    4)
      install_brew
      install_python
      ;;
    5)
      install_brew
      install_node
      ;;
    6)
      install_brew
      install_ruby
      ;;
    7)
      install_brew
      install_apps
      ;;
    8)
      install_brew
      install_docker
      ;;
    9)
      apply_macos_tweaks
      ;;
    10)
      cleanup
      ;;
    11)
      echo "Goodbye! 👋"
      exit 0
      ;;
    *)
      error "Invalid option"
      exit 1
      ;;
  esac

  echo ""
  success "✅ Setup finished!"
  warn "🔄 Please restart your terminal (or run 'source ~/.zshrc') to activate all changes."
  echo ""
}

main "$@"