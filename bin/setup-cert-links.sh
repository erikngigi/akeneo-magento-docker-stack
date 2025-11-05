#!/usr/bin/env bash

##############################################################################
# Setup Certificate Symbolic Links
# 
# This script creates symbolic links from Let's Encrypt certificates
# to a location that can be mounted in Docker containers.
##############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths
LETSENCRYPT_DIR="/etc/letsencrypt"
CERT_LINK_DIR="$PROJECT_ROOT/templates/nginx/certs"

# Default domains (edit these to match your domains)
DEFAULT_DOMAINS=(
    "akeneo.yourdomain.com"
    "magento.yourdomain.com"
)

# Will be populated based on user selection
SELECTED_DOMAINS=()

##############################################################################
# Functions
##############################################################################

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_success() {
    print_message "$GREEN" "✓ $1"
}

print_error() {
    print_message "$RED" "✗ $1"
}

print_info() {
    print_message "$BLUE" "ℹ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_letsencrypt() {
    if [ ! -d "$LETSENCRYPT_DIR" ]; then
        print_error "Let's Encrypt directory not found: $LETSENCRYPT_DIR"
        print_info "Please install and run certbot first"
        exit 1
    fi
    print_success "Let's Encrypt directory found"
}

create_cert_directory() {
    if [ ! -d "$CERT_LINK_DIR" ]; then
        mkdir -p "$CERT_LINK_DIR"
        print_success "Created certificate link directory: $CERT_LINK_DIR"
    else
        print_info "Certificate link directory exists: $CERT_LINK_DIR"
    fi
}

list_available_certificates() {
    print_info "Available Let's Encrypt certificates:"
    echo ""
    
    if [ ! -d "$LETSENCRYPT_DIR/live" ]; then
        print_warning "No certificates found"
        return 1
    fi
    
    local count=0
    for cert_dir in "$LETSENCRYPT_DIR/live"/*; do
        if [ -d "$cert_dir" ] && [ "$(basename "$cert_dir")" != "README" ]; then
            local domain=$(basename "$cert_dir")
            echo "  - $domain"
            ((count++))
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_warning "No certificates found"
        return 1
    fi
    
    echo ""
    return 0
}

create_symlinks() {
    local domain=$1
    local le_domain_dir="$LETSENCRYPT_DIR/live/$domain"
    
    if [ ! -d "$le_domain_dir" ]; then
        print_warning "Certificate not found for: $domain"
        print_info "Run: sudo certbot certonly --standalone -d $domain"
        return 1
    fi
    
    print_info "Creating symlinks for: $domain"
    
    # Create domain directory
    local domain_cert_dir="$CERT_LINK_DIR/live/$domain"
    mkdir -p "$domain_cert_dir"
    
    # Remove old symlinks if they exist
    rm -f "$domain_cert_dir/fullchain.pem"
    rm -f "$domain_cert_dir/privkey.pem"
    rm -f "$domain_cert_dir/chain.pem"
    rm -f "$domain_cert_dir/cert.pem"
    
    # Create symbolic links
    ln -sf "$le_domain_dir/fullchain.pem" "$domain_cert_dir/fullchain.pem"
    ln -sf "$le_domain_dir/privkey.pem" "$domain_cert_dir/privkey.pem"
    ln -sf "$le_domain_dir/chain.pem" "$domain_cert_dir/chain.pem"
    ln -sf "$le_domain_dir/cert.pem" "$domain_cert_dir/cert.pem"
    
    # Set permissions
    # 755 = Owner: rwx, Group: r-x, Others: r-x
    # This allows Docker containers to read the certificates
    chmod 755 "$domain_cert_dir"
    
    # Ensure the user running Docker can read the symlinks
    # Get the user who invoked sudo (if applicable)
    if [ -n "$SUDO_USER" ]; then
        chown -h "$SUDO_USER:$SUDO_USER" "$domain_cert_dir"/*.pem 2>/dev/null || true
    fi
    
    print_success "Symlinks created for: $domain"
    print_info "  fullchain.pem -> $le_domain_dir/fullchain.pem"
    print_info "  privkey.pem -> $le_domain_dir/privkey.pem"
}

verify_symlinks() {
    print_info "Verifying symbolic links..."
    echo ""
    
    local all_good=true
    
    for domain in "${SELECTED_DOMAINS[@]}"; do
        local domain_cert_dir="$CERT_LINK_DIR/live/$domain"
        
        if [ -L "$domain_cert_dir/fullchain.pem" ] && [ -e "$domain_cert_dir/fullchain.pem" ]; then
            print_success "$domain: Certificates linked correctly"
            
            # Show certificate expiration
            local expiry=$(openssl x509 -enddate -noout -in "$domain_cert_dir/fullchain.pem" 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry" ]; then
                print_info "  Expires: $expiry"
            fi
        else
            print_warning "$domain: Certificates not linked or broken link"
            all_good=false
        fi
    done
    
    return 0
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create symbolic links from Let's Encrypt certificates to Docker volume.

OPTIONS:
    -h, --help              Show this help message
    -l, --list              List available certificates and exit
    -d, --domain DOMAIN     Link specific domain only
    -a, --all               Link all available certificates
    --config FILE           Use custom config file for domain list

EXAMPLES:
    $(basename "$0")                        # Link default domains
    $(basename "$0") -d akeneo.example.com  # Link specific domain
    $(basename "$0") -a                     # Link all available certificates
    $(basename "$0") -l                     # List available certificates

NOTES:
    - This script must be run with sudo
    - Certificates must exist in /etc/letsencrypt/live/
    - Docker containers need read access to the symlinked certificates

DIRECTORY PERMISSIONS (chmod 755):
    - Owner: Read + Write + Execute (full access)
    - Group: Read + Execute (can read and traverse)
    - Others: Read + Execute (can read and traverse)
    
    Docker containers need execute permission to traverse the directory
    and read permission to access the certificate files.

EOF
}

##############################################################################
# Main Script
##############################################################################

main() {
    local link_all=false
    local specific_domain=""
    local list_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -d|--domain)
                specific_domain="$2"
                shift 2
                ;;
            -a|--all)
                link_all=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_info "Certificate Symbolic Link Setup"
    echo ""
    
    # Check prerequisites
    check_root
    check_letsencrypt
    
    # List only mode
    if [ "$list_only" = true ]; then
        list_available_certificates
        exit 0
    fi
    
    create_cert_directory
    
    # Determine which domains to link
    if [ -n "$specific_domain" ]; then
        # Specific domain provided
        SELECTED_DOMAINS=("$specific_domain")
        print_info "Linking specific domain: $specific_domain"
    elif [ "$link_all" = true ]; then
        # Link all available certificates
        print_info "Linking all available certificates"
        echo ""
        
        if [ -d "$LETSENCRYPT_DIR/live" ]; then
            for cert_dir in "$LETSENCRYPT_DIR/live"/*; do
                if [ -d "$cert_dir" ] && [ "$(basename "$cert_dir")" != "README" ]; then
                    SELECTED_DOMAINS+=("$(basename "$cert_dir")")
                fi
            done
        fi
        
        if [ ${#SELECTED_DOMAINS[@]} -eq 0 ]; then
            print_error "No certificates found to link"
            exit 1
        fi
    else
        # Use default domains
        SELECTED_DOMAINS=("${DEFAULT_DOMAINS[@]}")
        print_info "Linking default domains"
    fi
    
    echo ""
    print_info "Domains to link:"
    for domain in "${SELECTED_DOMAINS[@]}"; do
        echo "  - $domain"
    done
    echo ""
    
    # Create symlinks for each domain
    print_info "Creating symbolic links..."
    echo ""
    
    for domain in "${SELECTED_DOMAINS[@]}"; do
        create_symlinks "$domain"
        echo ""
    done
    
    # Verify
    verify_symlinks
    
    echo ""
    print_success "Certificate symbolic links setup complete!"
    print_info "Certificates location: $CERT_LINK_DIR/live/<domain>/"
    echo ""
    print_info "Symbolic link structure:"
    print_info "  $CERT_LINK_DIR/live/<domain>/fullchain.pem -> /etc/letsencrypt/live/<domain>/fullchain.pem"
    print_info "  $CERT_LINK_DIR/live/<domain>/privkey.pem -> /etc/letsencrypt/live/<domain>/privkey.pem"
    echo ""
    print_warning "Remember to restart your Docker containers:"
    print_info "  docker compose restart nginx-webserver"
    echo ""
}

main "$@"
