#!/bin/bash
set -e

echo "Safe install for npm packages!"

module_name="$1"
echo "Install Package: $module_name";

# Fetch npm package tarball 
install_path=$(npm view $module_name --json | jq -r '.dist.tarball')
repo=$(npm view $module_name --json | jq -r '.repository.url')
repo=${repo#git+}
repo=${repo%.git}
version=$(npm view $module_name --json | jq -r '.version')

curl -so output.tar.gz $install_path

# Get GH release asset for this version provenance.
tarname=$(basename $(npm view @ianlewis/byob-test --json | jq -r '._resolved'))
wget -qO provenance.intoto.jsonl "${repo}/releases/download/v${version}/${tarname}.intoto.jsonl"

# Run SLSA verification.
echo ""
wget -q https://github.com/slsa-framework/slsa-verifier/releases/download/v2.0.1/slsa-verifier-linux-amd64
curl -s https://raw.githubusercontent.com/slsa-framework/slsa-verifier/main/SHA256SUM.md -o SHA256SUM.md
sed -n '2p' SHA256SUM.md | sha256sum --check --strict
chmod +x slsa-verifier-linux-amd64
./slsa-verifier-linux-amd64 verify-artifact output.tar.gz --provenance-path provenance.intoto.jsonl --source-uri ${repo#https://}

# Success! Install the package.
echo ""
echo "SLSA verification success! Installing module..."
npm install $module_name