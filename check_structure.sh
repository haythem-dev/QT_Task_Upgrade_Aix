#!/bin/sh
# Script to check the Qt source structure

echo "Current directory: $(pwd)"
echo "Listing contents of current directory:"
ls -la

echo "\nChecking for qtbase-everywhere-src-5.15.0 directory:"
if [ -d "qtbase-everywhere-src-5.15.0" ]; then
  echo "Directory exists. Checking its contents:"
  ls -la qtbase-everywhere-src-5.15.0
  
  echo "\nLooking for configure script:"
  if [ -f "qtbase-everywhere-src-5.15.0/configure" ]; then
    echo "Configure script exists. Checking permissions:"
    ls -la qtbase-everywhere-src-5.15.0/configure
    
    echo "\nChecking if configure script is executable:"
    if [ -x "qtbase-everywhere-src-5.15.0/configure" ]; then
      echo "Configure script is executable."
    else
      echo "Configure script is NOT executable."
    fi
  else
    echo "Configure script does NOT exist in expected location."
  fi
else
  echo "Directory qtbase-everywhere-src-5.15.0 does NOT exist."
fi

echo "\nSearching for configure script in current directory and subdirectories:"
find . -name "configure" -type f | grep -v "config.status" | head -10