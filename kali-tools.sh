#!/bin/bash

# ============================================================
#         RECON TOOLS FULL INSTALLATION SCRIPT
#         Includes: Go tools, Python tools, GF Patterns
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}[*] $1${NC}"; }
log_success() { echo -e "${GREEN}[+] $1${NC}"; }
log_warn()    { echo -e "${YELLOW}[!] $1${NC}"; }
log_error()   { echo -e "${RED}[-] $1${NC}"; }

# ============================================================
# MOVE GO BINARY TO /usr/bin (replaces old if exists)
# ============================================================
install_go_binary() {
    local TOOL_NAME="$1"
    local BIN_PATH="$HOME/go/bin/$TOOL_NAME"

    if [ -f "$BIN_PATH" ]; then
        if [ -f "/usr/bin/$TOOL_NAME" ]; then
            log_warn "Removing old /usr/bin/$TOOL_NAME"
            sudo rm -f "/usr/bin/$TOOL_NAME"
        fi
        sudo mv "$BIN_PATH" "/usr/bin/$TOOL_NAME"
        log_success "$TOOL_NAME moved to /usr/bin/$TOOL_NAME"
    else
        log_error "$TOOL_NAME binary not found at $BIN_PATH"
    fi
}

# ============================================================
# PREREQUISITES
# ============================================================
log_info "Updating system packages..."
sudo apt-get update -y

log_info "Installing prerequisites..."
sudo apt-get install -y \
    git curl wget build-essential \
    python3 python3-pip python3-venv \
    libpcap-dev gcc

# ============================================================
# GO INSTALLATION CHECK
# ============================================================
if ! command -v go &>/dev/null; then
    log_info "Go not found. Installing Go..."
    GO_VERSION="1.22.0"
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    log_success "Go installed: $(go version)"
else
    log_success "Go already installed: $(go version)"
fi

export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# ============================================================
# 1. FFUF
# ============================================================
log_info "Installing ffuf..."
go install github.com/ffuf/ffuf/v2@latest
install_go_binary "ffuf"
log_success "ffuf installed successfully."

# ============================================================
# 2. DALFOX
# ============================================================
log_info "Installing dalfox..."
go install github.com/hahwul/dalfox/v2@latest
install_go_binary "dalfox"
log_success "dalfox installed successfully."

# ============================================================
# 3. KATANA
# ============================================================
log_info "Installing katana..."
CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
install_go_binary "katana"
log_success "katana installed successfully."

# ============================================================
# 4. NUCLEI + TEMPLATES
# ============================================================
log_info "Installing nuclei..."
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
install_go_binary "nuclei"

log_info "Cloning nuclei-templates..."
NUCLEI_TEMPLATES_DIR="$HOME/nuclei-templates"
if [ -d "$NUCLEI_TEMPLATES_DIR" ]; then
    log_warn "nuclei-templates already exists. Pulling latest..."
    git -C "$NUCLEI_TEMPLATES_DIR" pull
else
    git clone https://github.com/projectdiscovery/nuclei-templates.git "$NUCLEI_TEMPLATES_DIR"
fi
log_success "nuclei installed and templates cloned to $NUCLEI_TEMPLATES_DIR"

# ============================================================
# 5. HTTPX
# ============================================================
log_info "Installing httpx..."
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
install_go_binary "httpx"
log_success "httpx installed successfully."

# ============================================================
# 6. SUBFINDER
# ============================================================
log_info "Installing subfinder..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
install_go_binary "subfinder"
log_success "subfinder installed successfully."

# ============================================================
# 7. WAYBACKURLS
# ============================================================
log_info "Installing waybackurls..."
go install github.com/tomnomnom/waybackurls@latest
install_go_binary "waybackurls"
log_success "waybackurls installed successfully."

# ============================================================
# 8. GAU
# ============================================================
log_info "Installing gau..."
GAU_DIR="/tmp/gau_build"
rm -rf "$GAU_DIR"
git clone https://github.com/lc/gau.git "$GAU_DIR"
cd "$GAU_DIR/cmd/gau"
go build -o gau
if [ -f "/usr/bin/gau" ]; then
    sudo rm -f /usr/bin/gau
fi
sudo mv gau /usr/bin/gau
cd ~
rm -rf "$GAU_DIR"
log_success "gau installed successfully."

# ============================================================
# 9. DNSX
# ============================================================
log_info "Installing dnsx..."
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
install_go_binary "dnsx"
log_success "dnsx installed successfully."

# ============================================================
# 10. HAKRAWLER
# ============================================================
log_info "Installing hakrawler..."
go install github.com/hakluke/hakrawler@latest
install_go_binary "hakrawler"
log_success "hakrawler installed successfully."

# ============================================================
# 11. PARAMSPIDER
# ============================================================
log_info "Installing ParamSpider..."
PARAMSPIDER_DIR="$HOME/tools/ParamSpider"
if [ -d "$PARAMSPIDER_DIR" ]; then
    log_warn "ParamSpider already exists. Pulling latest..."
    git -C "$PARAMSPIDER_DIR" pull
else
    mkdir -p "$HOME/tools"
    git clone https://github.com/devanshbatham/ParamSpider.git "$PARAMSPIDER_DIR"
fi
cd "$PARAMSPIDER_DIR"
pip3 install -r requirements.txt --break-system-packages 2>/dev/null || pip3 install -r requirements.txt
if [ -f "setup.py" ]; then
    python3 setup.py install 2>/dev/null || true
fi
# Make paramspider accessible globally
if [ -f "$PARAMSPIDER_DIR/paramspider.py" ]; then
    sudo ln -sf "$PARAMSPIDER_DIR/paramspider.py" /usr/bin/paramspider
    sudo chmod +x /usr/bin/paramspider
fi
cd ~
log_success "ParamSpider installed successfully."
log_info "  Usage: paramspider -d <domain>"

# ============================================================
# 12. OPENREDIREX
# ============================================================
log_info "Installing OpenRedireX..."
OPENREDIREX_DIR="$HOME/tools/OpenRedireX"
if [ -d "$OPENREDIREX_DIR" ]; then
    log_warn "OpenRedireX already exists. Pulling latest..."
    git -C "$OPENREDIREX_DIR" pull
else
    mkdir -p "$HOME/tools"
    git clone https://github.com/devanshbatham/OpenRedireX.git "$OPENREDIREX_DIR"
fi
cd "$OPENREDIREX_DIR"
if [ -f "setup.sh" ]; then
    chmod +x setup.sh
    bash setup.sh 2>/dev/null || true
fi
pip3 install -r requirements.txt --break-system-packages 2>/dev/null || pip3 install -r requirements.txt 2>/dev/null || true
# Make openredirex accessible globally
if [ -f "$OPENREDIREX_DIR/openredirex.py" ]; then
    sudo ln -sf "$OPENREDIREX_DIR/openredirex.py" /usr/bin/openredirex
    sudo chmod +x /usr/bin/openredirex
fi
cd ~
log_success "OpenRedireX installed successfully."
log_info "  Usage: cat urls.txt | openredirex"

# ============================================================
# 13. JIRA-LENS
# ============================================================
log_info "Installing Jira-Lens..."
JIRALENS_DIR="$HOME/tools/Jira-Lens"
if [ -d "$JIRALENS_DIR" ]; then
    log_warn "Jira-Lens already exists. Pulling latest..."
    git -C "$JIRALENS_DIR" pull
else
    mkdir -p "$HOME/tools"
    git clone https://github.com/MayankPandey01/Jira-Lens.git "$JIRALENS_DIR"
fi
cd "$JIRALENS_DIR"

# Create virtual environment
python3 -m venv pyenv
source pyenv/bin/activate

pip3 install -r requirements.txt 2>/dev/null || true
python3 setup.py install 2>/dev/null || true
pip3 install progressbar requests colorama 2>/dev/null || true

deactivate

# Create a wrapper script for Jira-Lens
sudo tee /usr/bin/jira-lens > /dev/null <<EOF
#!/bin/bash
cd "$JIRALENS_DIR"
source pyenv/bin/activate
python3 Jira-Lens.py "\$@"
deactivate
EOF
sudo chmod +x /usr/bin/jira-lens

cd ~
log_success "Jira-Lens installed successfully."
log_info "  Usage: jira-lens -u <target_url>"

# ============================================================
# GF PATTERNS INSTALLATION
# ============================================================
log_info "Installing GF tool..."
go install github.com/tomnomnom/gf@latest
install_go_binary "gf"

# Setup .gf directory
mkdir -p "$HOME/.gf"
TARGET_DIR="$HOME/.gf"

log_info "Cloning GF pattern repositories..."

GF_REPOS=(
    "https://github.com/tomnomnom/gfdecos"
    "https://github.com/r00tkie/grep-pattern"
    "https://github.com/mrofisr/gf-patterns"
    "https://github.com/robre/gf-patterns"
    "https://github.com/1ndianl33t/Gf-Patterns"
    "https://github.com/dwisiswant0/gf-secrets"
    "https://github.com/bp0lr/myGF_patterns"
    "https://github.com/cypher3107/GF-Patterns"
    "https://github.com/Matir/gf-patterns"
    "https://github.com/Isaac-The-Brave/GF-Patterns-Redux"
    "https://github.com/arthur4ires/gfPatterns"
    "https://github.com/R0X4R/Garud"
    "https://github.com/seqrity/Allin1gf"
    "https://github.com/Jude-Paul/GF-Patterns-For-Dangerous-PHP-Functions"
    "https://github.com/NitinYadav00/gf-patterns"
    "https://github.com/scumdestroy/YouthCrew-GF-Patterns"
)

GF_TMP_DIR="/tmp/gf_patterns_tmp"
mkdir -p "$GF_TMP_DIR"
cd "$GF_TMP_DIR"

for repo in "${GF_REPOS[@]}"; do
    REPO_NAME=$(basename "$repo")
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$repo")

    if [ "$HTTP_STATUS" = "200" ]; then
        log_info "Cloning $repo..."
        rm -rf "$REPO_NAME"
        if git clone --depth 1 "$repo" "$REPO_NAME" 2>/dev/null; then
            # Move all JSON pattern files to ~/.gf (overwrite existing)
            find "$REPO_NAME" -name "*.json" -exec bash -c '
                src="$1"; dst="'"$TARGET_DIR"'/$(basename "$src")"
                if [ -f "$dst" ]; then rm -f "$dst"; fi
                cp "$src" "$dst"
            ' _ {} \;
            find "$REPO_NAME" -name "*.JSON" -exec bash -c '
                src="$1"; dst="'"$TARGET_DIR"'/$(basename "$src")"
                if [ -f "$dst" ]; then rm -f "$dst"; fi
                cp "$src" "$dst"
            ' _ {} \;
            rm -rf "$REPO_NAME"
            log_success "Patterns from $REPO_NAME installed."
        else
            log_warn "Failed to clone $repo, skipping."
        fi
    else
        log_warn "$repo returned HTTP $HTTP_STATUS — skipping."
    fi
done

cd ~
rm -rf "$GF_TMP_DIR"
log_success "GF patterns installed to $TARGET_DIR"

# Setup gf completions
if [ -d "$HOME/go/src/github.com/tomnomnom/gf" ]; then
    cp "$HOME/go/src/github.com/tomnomnom/gf/gf-completion.bash" "$HOME/.gf/" 2>/dev/null || true
fi

# ============================================================
# PATH SETUP IN .bashrc / .zshrc
# ============================================================
log_info "Setting up PATH in shell config..."

SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

grep -q 'export PATH=$PATH:/usr/local/go/bin' "$SHELL_RC" 2>/dev/null || \
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$SHELL_RC"

grep -q 'source ~/.gf/gf-completion.bash' "$SHELL_RC" 2>/dev/null || \
    echo 'source ~/.gf/gf-completion.bash 2>/dev/null || true' >> "$SHELL_RC"

# ============================================================
# FINAL SUMMARY
# ============================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}         ALL TOOLS INSTALLED SUCCESSFULLY!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${CYAN}Go Tools (available in /usr/bin):${NC}"
for tool in ffuf dalfox katana nuclei httpx subfinder waybackurls dnsx hakrawler gau gf; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✔${NC} $tool"
    else
        echo -e "  ${RED}✘${NC} $tool (check manually)"
    fi
done

echo ""
echo -e "${CYAN}Python Tools:${NC}"
for tool in paramspider openredirex jira-lens; do
    if command -v "$tool" &>/dev/null || [ -f "/usr/bin/$tool" ]; then
        echo -e "  ${GREEN}✔${NC} $tool"
    else
        echo -e "  ${RED}✘${NC} $tool (check manually)"
    fi
done

echo ""
echo -e "${CYAN}GF Patterns:${NC}"
GF_COUNT=$(ls "$HOME/.gf/"*.json 2>/dev/null | wc -l)
echo -e "  ${GREEN}✔${NC} $GF_COUNT pattern files installed to ~/.gf/"

echo ""
echo -e "${YELLOW}NOTE: Run 'source ~/.bashrc' (or restart terminal) to apply PATH changes.${NC}"
echo ""
