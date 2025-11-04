#!/usr/bin/env bash

##############################################################################
# Self-Signed Certificate Generator
# 
# This script generates self-signed SSL certificates for Akeneo and Magento
# domains for local development and testing purposes.
#
# Usage: ./bin/generate-certs.sh
##############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Resolve the real path of this script (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Certificate configuration
CERT_DIR="$PROJECT_ROOT/templates/nginx/certs"
CERT_DAYS=365
KEY_SIZE=2048

# Certificate details
COUNTRY="US"
STATE="State"
CITY="City"
ORGANIZATION="Development"
ORGANIZATIONAL_UNIT="IT"

# Domains to generate certificates for
DOMAINS=(
    "akeneo.local"
    "magento.local"
)

##############################################################################
# Functions
##############################################################################

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print header
print_header() {
    echo ""
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
    echo ""
}

# Print success message
print_success() {
    print_message "$GREEN" "✓ $1"
}

# Print error message
print_error() {
    print_message "$RED" "✗ $1"
}

# Print warning message
print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

# Print info message
print_info() {
    print_message "$BLUE" "ℹ $1"
}

# Check if OpenSSL is installed
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed. Please install it first."
        exit 1
    fi
    print_success "OpenSSL is installed: $(openssl version)"
}

# Create certificate directory
create_cert_directory() {
    if [ ! -d "$CERT_DIR" ]; then
        mkdir -p "$CERT_DIR"
        print_success "Created certificate directory: $CERT_DIR"
    else
        print_info "Certificate directory already exists: $CERT_DIR"
    fi
}

# Generate certificate for a domain
generate_certificate() {
    local domain=$1
    local key_file="$CERT_DIR/${domain}.key"
    local cert_file="$CERT_DIR/${domain}.crt"
    
    print_info "Generating certificate for: $domain"
    
    # Check if certificate already exists
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        print_warning "Certificate already exists for $domain"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping $domain"
            return 0
        fi
    fi
    
    # Generate the certificate
    if openssl req -x509 -nodes -days "$CERT_DAYS" -newkey rsa:"$KEY_SIZE" \
        -keyout "$key_file" \
        -out "$cert_file" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$domain" \
        2>/dev/null; then
        
        # Set appropriate permissions
        chmod 600 "$key_file"
        chmod 644 "$cert_file"
        
        print_success "Certificate generated successfully for $domain"
        print_info "  Key:  $key_file"
        print_info "  Cert: $cert_file"
    else
        print_error "Failed to generate certificate for $domain"
        return 1
    fi
}

# Display certificate information
display_cert_info() {
    local domain=$1
    local cert_file="$CERT_DIR/${domain}.crt"
    
    if [ -f "$cert_file" ]; then
        print_info "Certificate details for $domain:"
        openssl x509 -in "$cert_file" -noout -subject -dates -fingerprint 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
    fi
}

# Generate SAN (Subject Alternative Name) certificate
generate_san_certificate() {
    local domain=$1
    local key_file="$CERT_DIR/${domain}.key"
    local cert_file="$CERT_DIR/${domain}.crt"
    local config_file="$CERT_DIR/${domain}.cnf"
    
    print_info "Generating SAN certificate for: $domain"
    
    # Create OpenSSL configuration file with SAN
    cat > "$config_file" <<EOF
[req]
default_bits = $KEY_SIZE
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = $COUNTRY
ST = $STATE
L = $CITY
O = $ORGANIZATION
OU = $ORGANIZATIONAL_UNIT
CN = $domain

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = www.$domain
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

    # Generate the certificate with SAN
    if openssl req -x509 -nodes -days "$CERT_DAYS" -newkey rsa:"$KEY_SIZE" \
        -keyout "$key_file" \
        -out "$cert_file" \
        -config "$config_file" \
        -extensions v3_req \
        2>/dev/null; then
        
        # Set appropriate permissions
        chmod 600 "$key_file"
        chmod 644 "$cert_file"
        
        # Remove config file
        rm -f "$config_file"
        
        print_success "SAN certificate generated successfully for $domain"
        print_info "  Key:  $key_file"
        print_info "  Cert: $cert_file"
    else
        print_error "Failed to generate SAN certificate for $domain"
        rm -f "$config_file"
        return 1
    fi
}

# List all certificates
list_certificates() {
    print_header "Existing Certificates"
    
    if [ "$(ls -A "$CERT_DIR"/*.crt 2>/dev/null)" ]; then
        for cert in "$CERT_DIR"/*.crt; do
            local domain=$(basename "$cert" .crt)
            print_info "Domain: $domain"
            display_cert_info "$domain"
            echo ""
        done
    else
        print_warning "No certificates found in $CERT_DIR"
    fi
}

# Clean all certificates
clean_certificates() {
    print_warning "This will delete all certificates in $CERT_DIR"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$CERT_DIR"/*.key "$CERT_DIR"/*.crt "$CERT_DIR"/*.cnf
        print_success "All certificates removed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Show usage instructions
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate self-signed SSL certificates for local development.

OPTIONS:
    -h, --help          Show this help message
    -l, --list          List all existing certificates
    -c, --clean         Remove all certificates
    -s, --san           Generate certificates with Subject Alternative Names
    -d, --domain DOMAIN Generate certificate for specific domain only
    -v, --verbose       Show certificate details after generation

EXAMPLES:
    $(basename "$0")                    # Generate all certificates
    $(basename "$0") -s                 # Generate all certificates with SAN
    $(basename "$0") -d akeneo.local    # Generate only for akeneo.local
    $(basename "$0") -l                 # List all certificates
    $(basename "$0") -c                 # Clean all certificates

EOF
}

##############################################################################
# Main Script
##############################################################################

main() {
    local use_san=false
    local specific_domain=""
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                check_openssl
                list_certificates
                exit 0
                ;;
            -c|--clean)
                clean_certificates
                exit 0
                ;;
            -s|--san)
                use_san=true
                shift
                ;;
            -d|--domain)
                specific_domain="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Print header
    print_header "Self-Signed Certificate Generator"
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    check_openssl
    
    # Create certificate directory
    create_cert_directory
    
    echo ""
    print_info "Configuration:"
    print_info "  Certificate directory: $CERT_DIR"
    print_info "  Certificate validity: $CERT_DAYS days"
    print_info "  Key size: $KEY_SIZE bits"
    print_info "  SAN enabled: $use_san"
    echo ""
    
    # Generate certificates
    if [ -n "$specific_domain" ]; then
        # Generate for specific domain only
        if $use_san; then
            generate_san_certificate "$specific_domain"
        else
            generate_certificate "$specific_domain"
        fi
        
        if $verbose; then
            echo ""
            display_cert_info "$specific_domain"
        fi
    else
        # Generate for all domains
        for domain in "${DOMAINS[@]}"; do
            if $use_san; then
                generate_san_certificate "$domain"
            else
                generate_certificate "$domain"
            fi
            
            if $verbose; then
                echo ""
                display_cert_info "$domain"
            fi
            echo ""
        done
    fi
    
    # Summary
    echo ""
    print_header "Certificate Generation Complete"
    print_success "All certificates have been generated in: $CERT_DIR"
    echo ""
    print_info "Next steps:"
    print_info "  1. Update your Docker Compose configuration"
    print_info "  2. Restart your Nginx container"
    print_info "  3. Trust the certificates in your system (optional)"
    echo ""
    print_warning "Note: These are self-signed certificates for development only."
    print_warning "Browsers will show security warnings until you trust them."
    echo ""
}

# Run main function
main "$@"
