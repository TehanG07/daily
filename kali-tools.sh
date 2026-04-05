#!/bin/bash

# ============================================================
#     DISK SPACE FIX + SAFE RECON TOOLS INSTALLER
#     Fixes: "No space left on device" during go install
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}[*] $1${NC}"; }
log_success() { echo -e "${GREEN}[+] $1${NC}"; }
log_warn()    { echo -e "${YELLOW}[!] $1${NC}"; }
log_error()   { echo -e "${RED}[-] $1${NC}"; }

# ============================================================
# STEP 1: SHOW DISK USAGE BEFORE CLEANUP
# ============================================================
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}         DISK SPACE BEFORE CLEANUP${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
df -h /
echo ""

# ============================================================
# STEP 2: AGGRESSIVE CLEANUP
# ============================================================
log_info "Cleaning /tmp ..."
sudo rm -rf /tmp/go-build* /tmp/go-link* /tmp/*.tar.gz /tmp/*.zip /tmp/gau_build /tmp/gf_patterns_tmp
sudo find /tmp -maxdepth 1 -type f -mmin +60 -delete 2>/dev/null

log_info "Cleaning apt cache..."
sudo apt-get clean -y
sudo apt-get autoclean -y
sudo apt-get autoremove -y

log_info "Cleaning Go build cache..."
go clean -cache -testcache -modcache 2>/dev/null || true

log_info "Removing old Go module downloads..."
rm -rf "$HOME/go/pkg/mod/cache" 2>/dev/null || true

log_info "Cleaning old Go binaries (if duplicate)..."
find "$HOME/go/bin" -type f | while read bin; do
    name=$(basename "$bin")
    if [ -f "/usr/bin/$name" ]; then
        log_warn "Removing duplicate in ~/go/bin: $name"
        rm -f "$bin"
    fi
done

log_info "Removing leftover temp build dirs..."
rm -rf /tmp/nuclei_build /tmp/katana_build /tmp/httpx_build 2>/dev/null || true

# Check for large files in home
log_info "Finding large files (>100MB) in home..."
find "$HOME" -maxdepth 4 -type f -size +100M 2>/dev/null | while read f; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    log_warn "Large file: $f ($SIZE)"
done

# ============================================================
# STEP 3: SHOW DISK USAGE AFTER CLEANUP
# ============================================================
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}         DISK SPACE AFTER CLEANUP${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
df -h /
echo ""

FREE_KB=$(df / | tail -1 | awk '{print $4}')
FREE_GB=$(echo "scale=1; $FREE_KB / 1024 / 1024" | bc 2>/dev/null || echo "?")

if [ "$FREE_KB" -lt 2097152 ] 2>/dev/null; then
    log_error "Still less than 2GB free (${FREE_GB}GB). Tools may fail to compile."
    log_warn "Consider: sudo rm -rf /var/log/*.gz /var/cache/apt /snap/* (if snap is used)"
    log_warn "Or free up space manually and re-run."
    echo ""
    echo -e "${YELLOW}Continue anyway? (y/n):${NC}"
    read -r CONTINUE
    [ "$CONTINUE" != "y" ] && exit 1
else
    log_success "Enough space available (${FREE_GB}GB free). Proceeding..."
fi

# ============================================================
# CONFIGURE TMPDIR TO A BIGGER PARTITION (if /tmp is small)
# ============================================================
log_info "Setting TMPDIR to $HOME/tmp for Go linker..."
mkdir -p "$HOME/tmp"
export TMPDIR="$HOME/tmp"
export GOTMPDIR="$HOME/tmp"

# ============================================================
# HELPER FUNCTIONS
# ============================================================
install_go_binary() {
    local TOOL_NAME="$1"
    local BIN_PATH="$HOME/go/bin/$TOOL_NAME"
    if [ -f "$BIN_PATH" ]; then
        sudo rm -f "/usr/bin/$TOOL_NAME"
        sudo mv "$BIN_PATH" "/usr/bin/$TOOL_NAME"
        log_success "$TOOL_NAME → /usr/bin/$TOOL_NAME"
    else
        log_error "$TOOL_NAME binary not found at $BIN_PATH"
    fi
}

go_install_safe() {
    local TOOL="$1"
    local PKG="$2"
    log_info "Installing $TOOL ..."
    if TMPDIR="$HOME/tmp" GOTMPDIR="$HOME/tmp" go install "$PKG" 2>&1; then
        install_go_binary "$TOOL"
        log_success "$TOOL installed."
    else
        log_error "$TOOL installation failed. Skipping..."
    fi
    # Clean tmp after each install to free space
    rm -rf "$HOME/tmp/go-build"* "$HOME/tmp/go-link"* 2>/dev/null
}

export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# ============================================================
# INSTALL GO TOOLS (one by one, cleaning between each)
# ============================================================
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}         INSTALLING GO TOOLS${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo ""

go_install_safe "ffuf"      "github.com/ffuf/ffuf/v2@latest"
go_install_safe "dalfox"    "github.com/hahwul/dalfox/v2@latest"
go_install_safe "httpx"     "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install_safe "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install_safe "waybackurls" "github.com/tomnomnom/waybackurls@latest"
go_install_safe "dnsx"      "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install_safe "hakrawler" "github.com/hakluke/hakrawler@latest"
go_install_safe "gf"        "github.com/tomnomnom/gf@latest"

# Katana needs CGO
log_info "Installing katana (CGO_ENABLED=1)..."
if CGO_ENABLED=1 TMPDIR="$HOME/tmp" GOTMPDIR="$HOME/tmp" go install github.com/projectdiscovery/katana/cmd/katana@latest 2>&1; then
    install_go_binary "katana"
    log_success "katana installed."
else
    log_error "katana failed. Try: sudo apt-get install -y libpcap-dev and retry."
fi
rm -rf "$HOME/tmp/go-build"* "$HOME/tmp/go-link"* 2>/dev/null

# Nuclei — uses CGO via sqlite, needs extra deps
log_info "Installing nuclei dependencies..."
sudo apt-get install -y gcc libsqlite3-dev 2>/dev/null

log_info "Installing nuclei..."
if CGO_ENABLED=1 TMPDIR="$HOME/tmp" GOTMPDIR="$HOME/tmp" go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>&1; then
    install_go_binary "nuclei"
    log_success "nuclei installed."
else
    log_warn "nuclei CGO install failed. Trying CGO_ENABLED=0..."
    if CGO_ENABLED=0 TMPDIR="$HOME/tmp" GOTMPDIR="$HOME/tmp" go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>&1; then
        install_go_binary "nuclei"
        log_success "nuclei installed (CGO disabled)."
    else
        log_error "nuclei installation failed."
    fi
fi
rm -rf "$HOME/tmp/go-build"* "$HOME/tmp/go-link"* 2>/dev/null

# GAU (build from source)
log_info "Installing gau..."
GAU_DIR="$HOME/tmp/gau_build"
rm -rf "$GAU_DIR"
git clone https://github.com/lc/gau.git "$GAU_DIR" 2>&1
cd "$GAU_DIR/cmd/gau"
if TMPDIR="$HOME/tmp" go build -o gau 2>&1; then
    sudo rm -f /usr/bin/gau
    sudo mv gau /usr/bin/gau
    log_success "gau installed → /usr/bin/gau"
else
    log_error "gau build failed."
fi
cd ~
rm -rf "$GAU_DIR"

# ============================================================
# NUCLEI TEMPLATES
# ============================================================
log_info "Cloning/updating nuclei-templates..."
NUCLEI_TEMPLATES="$HOME/nuclei-templates"
if [ -d "$NUCLEI_TEMPLATES" ]; then
    git -C "$NUCLEI_TEMPLATES" pull
else
    git clone --depth 1 https://github.com/projectdiscovery/nuclei-templates.git "$NUCLEI_TEMPLATES"
fi

# ============================================================
# FINAL CHECK
# ============================================================
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}         INSTALLATION SUMMARY${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo ""

TOOLS="ffuf dalfox katana nuclei httpx subfinder waybackurls gau dnsx hakrawler gf"
for tool in $TOOLS; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✔${NC} $tool  →  $(which $tool)"
    else
        echo -e "  ${RED}✘${NC} $tool  →  NOT FOUND"
    fi
done

echo ""
df -h /
echo ""
log_success "Done! Run 'source ~/.bashrc' to refresh PATH."
echo ""
