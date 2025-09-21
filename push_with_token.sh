#!/bin/bash
# Script to push using the stored token
TOKEN=$(cat .git_token)
git push https://hgottipati:$TOKEN@github.com/hgottipati/StrongMe.git main
