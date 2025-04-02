#!/bin/bash
# Add Maven to PATH
export PATH=$PATH:/Users/dhruvchaubey/.jenkins/tools/hudson.tasks.Maven_MavenInstallation/mvn/bin
# Verify Maven is available
which mvn
mvn --version
# Run Snyk with Maven in PATH
snyk-macos test --json --severity-threshold=low
