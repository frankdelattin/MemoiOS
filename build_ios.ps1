#!/usr/bin/env pwsh

Write-Host "Building iOS app..."

# Verify ONNX models are present (but we won't use them for iOS)
Write-Host "Verifying ONNX models are present:"
if (Test-Path "assets/models") {
    Get-ChildItem -Path "assets/models" -Recurse | Format-Table Name, Length -AutoSize
    Get-ChildItem -Path "assets/models" -Recurse | ForEach-Object { 
        $size = [math]::Round($_.Length / 1MB, 1)
        Write-Host "$size`M`t$($_.FullName)"
    }
} else {
    Write-Host "No models directory found - this is expected for iOS-only build"
}

Write-Host "Building iOS app for testing..."

# Check if we're in a Flutter project
if (Test-Path "pubspec.yaml") {
    Write-Host "Flutter project detected"
    
    # Try to use flutter if available, otherwise provide instructions
    try {
        flutter --version
        Write-Host "Building com.snappapp.vectorcleanup for simulator (ios)..."
        flutter build ios --debug --simulator
    } catch {
        Write-Host "Flutter not found in PATH. Please install Flutter or use Xcode directly."
        Write-Host "To build with Xcode:"
        Write-Host "1. Open ios/Runner.xcworkspace in Xcode"
        Write-Host "2. Select a simulator target"
        Write-Host "3. Build and run (Cmd+R)"
    }
} else {
    Write-Host "Error: Not a Flutter project"
    exit 1
}
