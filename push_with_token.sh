#!/bin/bash
# Script to push using the stored token with build verification

echo "🔍 Running pre-push build verification..."

# Check if we're in the right directory
if [ ! -d "StrongMe" ]; then
    echo "❌ Error: StrongMe directory not found. Please run from project root."
    exit 1
fi

cd StrongMe

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: Uncommitted changes detected. Please commit all changes before pushing."
    echo "Uncommitted files:"
    git status --porcelain
    exit 1
fi

# Run Swift syntax check
echo "📝 Checking Swift syntax..."
if ! find . -name "*.swift" -exec swift -frontend -parse {} \; > /dev/null 2>&1; then
    echo "❌ Error: Swift syntax errors detected. Please fix before pushing."
    exit 1
fi

echo "✅ Swift syntax check passed"

# Check for common Swift issues
echo "🔍 Checking for common issues..."
if grep -r "import.*import" . --include="*.swift" > /dev/null 2>&1; then
    echo "⚠️  Warning: Duplicate imports detected. Consider cleaning up."
fi

if grep -r "TODO\|FIXME\|HACK" . --include="*.swift" > /dev/null 2>&1; then
    echo "⚠️  Warning: TODO/FIXME/HACK comments found in code."
fi

echo "✅ Pre-push checks completed successfully"

# Get token and push
echo "🚀 Pushing to GitHub..."
TOKEN=$(cat .git_token)
if git push https://hgottipati:$TOKEN@github.com/hgottipati/StrongMe.git main; then
    echo "✅ Successfully pushed to GitHub!"
else
    echo "❌ Push failed. Please check your connection and try again."
    exit 1
fi
