#!/bin/bash
set -e

# Read input arguments
TESTING_WORKFLOWS="$1"
LINTING_WORKFLOWS="$2"
BUILD_WORKFLOWS="$3"
DEPLOYMENT_WORKFLOWS="$4"
BASE_BRANCH="${5:-main}"
TEMPLATES_REPO="${6:-BenFielder/github-actions-controller}"

BRANCH_NAME="gh-actions-controller-update"
WORKFLOWS_DIR=".github/workflows"
TEMPLATES_DIR="templates"

echo "Setting up the following workflows:"
echo "  - Testing:    $TESTING_WORKFLOWS"
echo "  - Linting:    $LINTING_WORKFLOWS"
echo "  - Build:      $BUILD_WORKFLOWS"
echo "  - Deployment: $DEPLOYMENT_WORKFLOWS"
echo "  - Base Branch: $BASE_BRANCH"
echo "  - Templates:  $TEMPLATES_REPO"

# Cleanup function
cleanup() {
  echo "Cleaning up..."
  rm -rf "$TEMPLATES_DIR"
}
trap cleanup EXIT

# Setup git
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Force Git to use the GitHub Actions token
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}"

# Fetch and checkout base branch
git fetch origin "$BASE_BRANCH"

# Delete branch if it exists locally or remotely
git branch -D "$BRANCH_NAME" 2>/dev/null || true
git push origin --delete "$BRANCH_NAME" 2>/dev/null || true

# Create new branch from base
git checkout -b "$BRANCH_NAME" "origin/$BASE_BRANCH"

# Clone templates
echo "Cloning templates from https://github.com/$TEMPLATES_REPO..."
git clone "https://github.com/$TEMPLATES_REPO" "$TEMPLATES_DIR"

# Ensure workflows directory exists
mkdir -p "$WORKFLOWS_DIR"

# Track if any files were copied
FILES_COPIED=false

# Copy selected workflows
if [[ "$TESTING_WORKFLOWS" == "true" ]]; then
  echo "Copying testing workflows..."
  if cp "$TEMPLATES_DIR/templates/testing"/*.yml "$WORKFLOWS_DIR/" 2>/dev/null; then
    FILES_COPIED=true
    echo "Testing workflows pulled from repo"
  else
    echo "No testing workflows found"
  fi
fi

if [[ "$LINTING_WORKFLOWS" == "true" ]]; then
  echo "Copying linting workflows..."
  if cp "$TEMPLATES_DIR/templates/linting"/*.yml "$WORKFLOWS_DIR/" 2>/dev/null; then
    FILES_COPIED=true
    echo "Linting workflows pulled from repo"
  else
    echo "No linting workflows found"
  fi
fi

if [[ "$BUILD_WORKFLOWS" == "true" ]]; then
  echo "Copying build workflows..."
  if cp "$TEMPLATES_DIR/templates/building"/*.yml "$WORKFLOWS_DIR/" 2>/dev/null; then
    FILES_COPIED=true
    echo "Build workflows pulled from repo"
  else
    echo "No build workflows found"
  fi
fi

if [[ "$DEPLOYMENT_WORKFLOWS" == "true" ]]; then
  echo "Copying deployment workflows..."
  if cp "$TEMPLATES_DIR/templates/deploying"/*.yml "$WORKFLOWS_DIR/" 2>/dev/null; then
    FILES_COPIED=true
    echo "Deployment workflows pulled from repo"
  else
    echo "No deployment workflows found"
  fi
fi

# Check if any files were actually copied
if [[ "$FILES_COPIED" == "false" ]]; then
  echo "No workflows were copied. Exiting."
  exit 0
fi

# Commit changes
git add "$WORKFLOWS_DIR"
if git diff --staged --quiet; then
  echo "No changes to commit. Workflows may already be up to date."
  exit 0
fi

git commit -m "chore: Update workflows from github-actions-controller"

# Push branch
echo "Pushing changes to $BRANCH_NAME..."
git push -f origin "$BRANCH_NAME"

# Create or update PR
echo "Creating pull request..."
if gh pr view "$BRANCH_NAME" --json number &>/dev/null; then
  echo "PR already exists, updating..."
  gh pr edit "$BRANCH_NAME" \
    --title "chore: Update GitHub Actions workflows" \
    --body "This PR updates the workflows via \`github-actions-controller\`.

## Workflows Updated:
- Testing: $TESTING_WORKFLOWS
- Linting: $LINTING_WORKFLOWS
- Build: $BUILD_WORKFLOWS
- Deployment: $DEPLOYMENT_WORKFLOWS

Please review the changes before merging."
else
  gh pr create \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" \
    --title "chore: Update GitHub Actions workflows" \
    --body "This PR updates the workflows via \`github-actions-controller\`.

## Workflows Updated:
- Testing: $TESTING_WORKFLOWS
- Linting: $LINTING_WORKFLOWS
- Build: $BUILD_WORKFLOWS
- Deployment: $DEPLOYMENT_WORKFLOWS

Please review the changes before merging."
fi

echo "✓ Done!"