#! /bin/bash

# VARIABLES
githubUsername=$1
repoName=$2
description=$3
visibility=$4
githubToken=$5

# Confirm variables are defined
while [ -z "$githubUsername" ] || [ -z "$repoName" ] || [ -z "$githubToken" ] || [ -z "$description" ] || [ -z "$visibility" ]
do
    echo "Provide github credentials"
    read -r -p "Github Username: " githubUsername #Profile username
    read -r -p "Github Repository name: " repoName #Repo name
    read -r -p "Github Repository description: " description #Repo description
    read -r -p "Make Repository Public (visibility) - Y/N: " answer #Repo visibility
    case "$answer" in
        [yY] | [yY][eE][sS]) visibility=false ;; # public
        [nN] | [nN][oO]) visibility=true ;; # private
        *) 
            echo "❌ You entered an invalid option, exiting..." 
            exit 1
            ;;
    esac
    read -s -r -p "Github Token (hidden): " githubToken #Profile auth token
done

# Create project directory || Confirm directory path
mkdir "$repoName"

# Navigate into project directory || Confirm directory path
cd "$repoName"

echo "Creating $repoName repository..."
echo "# $description" >> README.md

# Confirm if jq is installed before continuation
if ! command -v jq &> /dev/null; then
    echo "❌ 'jq' is not installed."
    echo "➡️  Please install 'jq' manually:"
    echo "   - Windows: Download from https://stedolan.github.io/jq/download/"
    echo "   - macOS: brew install jq"
    echo "   - Ubuntu/Linux: sudo apt install jq"
    exit 1
fi

# Initialize Git
git init
git add .
git commit -m "Initialized github repository"

# Create remote repository
curl -s -u "$githubUsername:$githubToken" -X POST https://api.github.com/user/repos \
    -d "{\"name\":\"$repoName\",\"private\":$visibility,\"description\":\"$description\"}" \
    -o response.json

# Exit on Error
errorMsg=$(jq -r '.message // empty' response.json)
if [ -n "$errorMsg" ]; then
    echo "❌ GitHub Error: $errorMsg"
    exit 1
fi

# Get Repository URL
repoUrl=$(jq -r '.clone_url' response.json)

# Display repository url
echo "Github repository created at: $repoUrl"

# Delete json file created
rm response.json

# Rename git branch, add remote url and push.
git branch -M main
git remote add origin $repoUrl
git push -u origin main

echo "Operation completed ✅✅✅"