#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VM_NAME="${VM_NAME:-ansible-test}"
VM_CPUS="${VM_CPUS:-2}"
VM_MEM="${VM_MEM:-4G}"
VM_DISK="${VM_DISK:-20G}"
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
PLAYBOOK="${PLAYBOOK:-playbooks/after_format.yaml}"
EXTRA_ARGS="${EXTRA_ARGS:-}"
VAULT_PASS_FILE="${VAULT_PASS_FILE:-}"
KEEP_VM="${KEEP_VM:-false}"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Ansible VM Test Runner${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check if multipass is installed
check_multipass() {
    if command -v multipass &> /dev/null; then
        echo -e "${GREEN}✓${NC} Multipass is installed"
        multipass version
        return 0
    else
        echo -e "${YELLOW}⚠${NC}  Multipass is not installed"
        return 1
    fi
}

# Function to install multipass
install_multipass() {
    echo -e "${YELLOW}→${NC} Installing Multipass..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if snap is available
        if command -v snap &> /dev/null; then
            echo -e "${BLUE}  Using snap to install Multipass...${NC}"
            sudo snap install multipass
        else
            echo -e "${RED}✗${NC} Snap is not available. Please install Multipass manually:"
            echo -e "  ${BLUE}https://multipass.run/install${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${BLUE}  Using Homebrew to install Multipass...${NC}"
            brew install --cask multipass
        else
            echo -e "${RED}✗${NC} Homebrew is not available. Please install Multipass manually:"
            echo -e "  ${BLUE}https://multipass.run/install${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} Unsupported OS. Please install Multipass manually:"
        echo -e "  ${BLUE}https://multipass.run/install${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Multipass installed successfully"
}

# Function to cleanup existing VM
cleanup_vm() {
    if multipass list | grep -q "^${VM_NAME}"; then
        echo -e "${YELLOW}→${NC} Cleaning up existing VM: ${VM_NAME}"
        multipass delete "$VM_NAME" || true
        multipass purge || true
        echo -e "${GREEN}✓${NC} Cleanup complete"
    fi
}

# Function to create and prepare VM
create_vm() {
    echo -e "${YELLOW}→${NC} Creating VM: ${VM_NAME}"
    echo -e "${BLUE}  Configuration:${NC}"
    echo -e "    CPUs: ${VM_CPUS}"
    echo -e "    Memory: ${VM_MEM}"
    echo -e "    Disk: ${VM_DISK}"
    echo -e "    Ubuntu: ${UBUNTU_VERSION}"
    echo ""
    
    multipass launch "$UBUNTU_VERSION" \
        --name "$VM_NAME" \
        --cpus "$VM_CPUS" \
        --memory "$VM_MEM" \
        --disk "$VM_DISK"
    
    echo -e "${GREEN}✓${NC} VM created successfully"
}

# Function to transfer ansible repo
transfer_repo() {
    echo -e "${YELLOW}→${NC} Transferring Ansible repository to VM..."
    
    # Create a temporary directory in the VM
    multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/ansible
    
    # Transfer the repo (excluding .git, cache, and test directories)
    echo -e "${BLUE}  Copying files...${NC}"
    
    # Use tar to transfer (more reliable than multipass transfer for directories)
    echo -e "${BLUE}  Creating archive...${NC}"
    tar -czf /tmp/ansible-repo.tar.gz -C "$REPO_ROOT" \
        --exclude='.git' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        --exclude='.molecule' \
        --exclude='.pytest_cache' \
        . 2>&1 || {
        echo -e "${RED}✗${NC} Failed to create archive"
        exit 1
    }
    
    if [[ ! -f /tmp/ansible-repo.tar.gz ]]; then
        echo -e "${RED}✗${NC} Archive file not created"
        exit 1
    fi
    
    echo -e "${BLUE}  Archive size: $(du -h /tmp/ansible-repo.tar.gz | cut -f1)${NC}"
    
    echo -e "${BLUE}  Transferring to VM...${NC}"
    
    # Use cat/pipe method as multipass transfer has issues with /tmp
    cat /tmp/ansible-repo.tar.gz | multipass exec "$VM_NAME" -- bash -c "cat > /tmp/ansible-repo.tar.gz" || {
        echo -e "${RED}✗${NC} Failed to transfer repository"
        rm -f /tmp/ansible-repo.tar.gz
        exit 1
    }
    
    multipass exec "$VM_NAME" -- bash -c "cd /home/ubuntu/ansible && tar -xzf /tmp/ansible-repo.tar.gz" || {
        echo -e "${RED}✗${NC} Failed to extract repository"
        rm -f /tmp/ansible-repo.tar.gz
        exit 1
    }
    
    # Clean up
    rm -f /tmp/ansible-repo.tar.gz
    multipass exec "$VM_NAME" -- rm -f /tmp/ansible-repo.tar.gz
    
    echo -e "${GREEN}✓${NC} Repository transferred"
}

# Function to install dependencies in VM
install_dependencies() {
    echo -e "${YELLOW}→${NC} Installing dependencies in VM..."
    
    multipass exec "$VM_NAME" -- bash -c "
        set -e
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            ansible \
            git \
            python3-pip \
            python3-venv \
            openssh-client \
            gnupg \
            ca-certificates
        
        # Install ansible.posix collection (needed for authorized_key module)
        ansible-galaxy collection install ansible.posix
    "
    
    echo -e "${GREEN}✓${NC} Dependencies installed"
}

# Function to run playbook in VM
run_playbook() {
    echo -e "${YELLOW}→${NC} Running playbook: ${PLAYBOOK}"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Playbook Output${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Prepare vault password file if provided
    VAULT_CMD=""
    if [[ -n "$VAULT_PASS_FILE" ]]; then
        # Expand tilde to actual home directory
        EXPANDED_VAULT_PATH="${VAULT_PASS_FILE/#\~/$HOME}"
        
        if [[ -f "$EXPANDED_VAULT_PATH" ]]; then
            echo -e "${BLUE}  Using vault password file: ${EXPANDED_VAULT_PATH}${NC}"
            
            # Transfer vault password file to VM
            cat "$EXPANDED_VAULT_PATH" | multipass exec "$VM_NAME" -- bash -c "cat > /home/ubuntu/.vault_pass && chmod 600 /home/ubuntu/.vault_pass" || {
                echo -e "${RED}✗${NC} Failed to transfer vault password file"
                exit 1
            }
            
            VAULT_CMD="--vault-password-file /home/ubuntu/.vault_pass"
            echo -e "${GREEN}✓${NC} Vault password file transferred"
        else
            echo -e "${YELLOW}⚠${NC}  Vault password file not found: ${EXPANDED_VAULT_PATH}"
            echo -e "${YELLOW}⚠${NC}  Continuing without vault password - encrypted files will fail to decrypt"
        fi
    fi
    
    # Run the playbook
    multipass exec "$VM_NAME" -- bash -c "
        cd /home/ubuntu/ansible
        ansible-playbook $PLAYBOOK $VAULT_CMD $EXTRA_ARGS
    " || {
        echo ""
        echo -e "${RED}✗${NC} Playbook execution failed"
        echo -e "${YELLOW}→${NC} VM is still running. You can debug with:"
        echo -e "    ${BLUE}multipass shell $VM_NAME${NC}"
        echo -e "${YELLOW}→${NC} To destroy the VM when done:"
        echo -e "    ${BLUE}multipass delete $VM_NAME && multipass purge${NC}"
        exit 1
    }
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓${NC} Playbook completed successfully"
}

# Function to show VM info
show_vm_info() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  VM Information${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    multipass info "$VM_NAME"
    echo ""
    echo -e "${YELLOW}→${NC} To access the VM:"
    echo -e "    ${BLUE}multipass shell $VM_NAME${NC}"
    echo ""
    echo -e "${YELLOW}→${NC} To stop the VM:"
    echo -e "    ${BLUE}multipass stop $VM_NAME${NC}"
    echo ""
    echo -e "${YELLOW}→${NC} To destroy the VM:"
    echo -e "    ${BLUE}multipass delete $VM_NAME && multipass purge${NC}"
    echo ""
}

# Function to cleanup VM after successful run
cleanup_after_run() {
    if [[ "$KEEP_VM" != "true" ]]; then
        echo -e "${YELLOW}→${NC} Cleaning up VM..."
        multipass delete "$VM_NAME" || true
        multipass purge || true
        echo -e "${GREEN}✓${NC} VM cleaned up"
    else
        show_vm_info
    fi
}

# Main execution
main() {
    cd "$REPO_ROOT"
    
    # Check and install multipass if needed
    if ! check_multipass; then
        echo ""
        read -p "Install Multipass now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_multipass
        else
            echo -e "${RED}✗${NC} Multipass is required. Exiting."
            exit 1
        fi
    fi
    
    echo ""
    
    # Cleanup any existing VM with the same name
    cleanup_vm
    
    echo ""
    
    # Create and setup VM
    create_vm
    echo ""
    
    transfer_repo
    echo ""
    
    install_dependencies
    echo ""
    
    # Run the playbook
    run_playbook
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Test completed successfully! ✓${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    # Cleanup or show info
    cleanup_after_run
}

# Run main function
main

