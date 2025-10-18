#!/bin/bash

# QLORAX GitHub Repository Setup Script
# This script helps you push your QLORAX project to GitHub

echo "🚀 QLORAX GitHub Repository Setup"
echo "=================================="
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Run 'git init' first."
    exit 1
fi

echo "✅ Git repository detected"

# Check if there are any remotes
REMOTES=$(git remote)
if [ -z "$REMOTES" ]; then
    echo "⚠️  No remote repositories configured"
    echo ""
    echo "📋 To push to GitHub, you need to:"
    echo "1. Create a repository on GitHub.com"
    echo "2. Copy the repository URL"
    echo "3. Run: git remote add origin YOUR_REPO_URL"
    echo "4. Run: git push -u origin main"
    echo ""
    echo "🌐 GitHub repository creation options:"
    echo "   • Go to: https://github.com/new"
    echo "   • Repository name: QLORAX"
    echo "   • Keep it Public (for free GitHub Actions)"
    echo "   • Don't initialize with README"
    echo ""
    
    # Provide the exact commands they need to run
    echo "📝 Commands to run after creating GitHub repository:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/QLORAX.git"
    echo "git push -u origin main"
    echo ""
else
    echo "✅ Remote repositories found:"
    git remote -v
    echo ""
    echo "🚀 Ready to push! Run:"
    echo "git push -u origin main"
fi

echo ""
echo "📊 Repository status:"
git status --short
echo ""

# Check if everything is committed
if git diff-index --quiet HEAD --; then
    echo "✅ All changes committed"
    
    # Show what will be pushed
    echo ""
    echo "📦 Files ready to push:"
    git ls-files | wc -l
    echo " files in repository"
    
    echo ""
    echo "🎯 After pushing, your GitHub Actions will:"
    echo "   • Build Docker images"
    echo "   • Run automated tests"
    echo "   • Enable one-click deployments"
    echo "   • Set up CI/CD pipeline"
    
else
    echo "⚠️  You have uncommitted changes"
    echo "Run 'git add .' and 'git commit -m \"message\"' first"
fi

echo ""
echo "🎉 Once pushed, visit your GitHub repository's Actions tab!"
echo "🌐 Deploy to Hugging Face Spaces, Cloud Run, Railway, or Render!"