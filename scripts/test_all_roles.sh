#!/usr/bin/env bash

set -euo pipefail

# Configuration
ROLES_DIR="playbooks/roles"
SCENARIO_NAME="default"
VENV_PATH="venv"
FAILED_ROLES=()
PASSED_ROLES=()
TOTAL_ROLES=0
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_status $BLUE "🔍 Checking prerequisites..."
    
    # Check if roles directory exists
    if [[ ! -d "$ROLES_DIR" ]]; then
        print_status $RED "❌ Roles directory '$ROLES_DIR' not found!"
        exit 1
    fi
    
    # Check for virtual environment and activate if available
    if [[ -d "$VENV_PATH" ]]; then
        print_status $YELLOW "🔧 Activating virtual environment..."
        source "$VENV_PATH/bin/activate"
    else
        print_status $YELLOW "⚠️  No virtual environment found at '$VENV_PATH', using system packages"
    fi
    
    # Check if molecule is available
    if ! command -v molecule &> /dev/null; then
        print_status $RED "❌ Molecule not found! Please install molecule first."
        print_status $YELLOW "   Try: pip install 'molecule[docker]' molecule-plugins[docker]"
        exit 1
    fi
    
    # Check if docker is available (if using docker driver)
    if ! command -v docker &> /dev/null; then
        print_status $YELLOW "⚠️  Docker not found! Some tests may fail if they use docker driver."
    fi
    
    print_status $GREEN "✅ Prerequisites check completed"
}

# Function to test a single role
test_role() {
    local role_dir=$1
    local role_name=$(basename "$role_dir")
    
    print_status $BLUE "🔧 Testing role: $role_name"
    
    if (cd "$role_dir" && molecule test --scenario-name "$SCENARIO_NAME" 2>&1); then
        print_status $GREEN "✅ $role_name passed"
        PASSED_ROLES+=("$role_name")
        return 0
    else
        print_status $RED "❌ $role_name failed"
        FAILED_ROLES+=("$role_name")
        return 1
    fi
}

# Function to print summary
print_summary() {
    echo
    print_status $BLUE "📊 Test Summary:"
    print_status $BLUE "================"
    print_status $GREEN "✅ Passed: ${#PASSED_ROLES[@]}/$TOTAL_ROLES"
    print_status $RED "❌ Failed: ${#FAILED_ROLES[@]}/$TOTAL_ROLES"
    
    if [[ ${#PASSED_ROLES[@]} -gt 0 ]]; then
        echo
        print_status $GREEN "Passed roles:"
        for role in "${PASSED_ROLES[@]}"; do
            echo "  ✅ $role"
        done
    fi
    
    if [[ ${#FAILED_ROLES[@]} -gt 0 ]]; then
        echo
        print_status $RED "Failed roles:"
        for role in "${FAILED_ROLES[@]}"; do
            echo "  ❌ $role"
        done
    fi
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--help]"
                echo "  --dry-run  Only validate structure, don't run tests"
                echo "  --help     Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_status $BLUE "🔍 Dry run: Validating role structure..."
    else
        print_status $BLUE "🚀 Starting Molecule tests for all roles..."
    fi
    
    check_prerequisites
    
    print_status $BLUE "🔍 Searching for Molecule scenarios in $ROLES_DIR..."
    
    # Find all roles with molecule directories
    local molecule_dirs
    mapfile -t molecule_dirs < <(find "$ROLES_DIR" -type d -name molecule)
    
    if [[ ${#molecule_dirs[@]} -eq 0 ]]; then
        print_status $YELLOW "⚠️  No molecule directories found in $ROLES_DIR"
        exit 0
    fi
    
    TOTAL_ROLES=${#molecule_dirs[@]}
    print_status $BLUE "📋 Found $TOTAL_ROLES roles with Molecule tests"
    
    # Test each role or just validate structure
    local exit_code=0
    for molecule_dir in "${molecule_dirs[@]}"; do
        role_dir=$(dirname "$molecule_dir")
        if [[ "$DRY_RUN" == "true" ]]; then
            role_name=$(basename "$role_dir")
            print_status $GREEN "✅ $role_name has molecule tests"
            PASSED_ROLES+=("$role_name")
        else
            if ! test_role "$role_dir"; then
                exit_code=1
            fi
        fi
    done
    
    print_summary
    
    if [[ $exit_code -eq 0 ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_status $GREEN "🎉 All roles have valid molecule test structure!"
        else
            print_status $GREEN "🎉 All Molecule tests completed successfully!"
        fi
    else
        print_status $RED "💥 Some tests failed!"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"
