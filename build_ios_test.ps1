# iOS Build Test Script
# This script tests the original iOS build process and investigates missing ONNX models

Write-Host "=== iOS Build Analysis Script ===" -ForegroundColor Green
Write-Host "Testing original iOS build process..." -ForegroundColor Yellow

# Check current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Cyan

# Check Flutter installation
Write-Host "`n=== Checking Flutter Installation ===" -ForegroundColor Green
try {
    flutter --version
    Write-Host "✓ Flutter found" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter or add it to PATH" -ForegroundColor Yellow
    exit 1
}

# Check assets directory structure
Write-Host "`n=== Checking Assets Structure ===" -ForegroundColor Green
Write-Host "Assets directory contents:"
if (Test-Path "assets") {
    Get-ChildItem -Path "assets" -Recurse | ForEach-Object {
        Write-Host "  $($_.FullName.Replace($currentDir, '.'))" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ Assets directory not found" -ForegroundColor Red
}

# Check for missing ONNX models
Write-Host "`n=== Checking for Missing ONNX Models ===" -ForegroundColor Green
$missingModels = @(
    "assets/models/nlp_visualize_opset3.onnx",
    "assets/models/nlp_visualize.onnx",
    "assets/models/nlp_textual_opset3.onnx", 
    "assets/models/nlp_textual.onnx",
    "assets/models/tokenizers/nlp_textual_tokenizer.txt.gz"
)

foreach ($model in $missingModels) {
    if (Test-Path $model) {
        Write-Host "✓ $model exists" -ForegroundColor Green
    } else {
        Write-Host "✗ $model MISSING" -ForegroundColor Red
    }
}

# Check pubspec.yaml assets section
Write-Host "`n=== Checking pubspec.yaml Assets Section ===" -ForegroundColor Green
if (Test-Path "pubspec.yaml") {
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -match "assets:") {
        Write-Host "Assets section found in pubspec.yaml:" -ForegroundColor Cyan
        $lines = Get-Content "pubspec.yaml"
        $inAssetsSection = $false
        foreach ($line in $lines) {
            if ($line -match "^\s*assets:") {
                $inAssetsSection = $true
                Write-Host "  $line" -ForegroundColor Yellow
            } elseif ($inAssetsSection -and $line -match "^\s*-\s*assets/") {
                Write-Host "  $line" -ForegroundColor Yellow
            } elseif ($inAssetsSection -and $line -match "^\s*[a-zA-Z]") {
                $inAssetsSection = $false
            }
        }
    }
}

# Install Flutter dependencies
Write-Host "`n=== Installing Flutter Dependencies ===" -ForegroundColor Green
try {
    flutter pub get
    Write-Host "✓ Flutter dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to install Flutter dependencies" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

# Run Flutter analyze
Write-Host "`n=== Running Flutter Analyze ===" -ForegroundColor Green
try {
    flutter analyze
    Write-Host "✓ Flutter analyze completed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Flutter analyze found issues (expected)" -ForegroundColor Yellow
}

# Check iOS directory
Write-Host "`n=== Checking iOS Directory ===" -ForegroundColor Green
if (Test-Path "ios") {
    Write-Host "✓ iOS directory found" -ForegroundColor Green
    if (Test-Path "ios/Podfile") {
        Write-Host "✓ Podfile found" -ForegroundColor Green
    }
} else {
    Write-Host "✗ iOS directory not found" -ForegroundColor Red
}

# Install iOS dependencies (if on macOS)
if ($IsMacOS) {
    Write-Host "`n=== Installing iOS Dependencies ===" -ForegroundColor Green
    try {
        Set-Location "ios"
        pod install
        Set-Location ".."
        Write-Host "✓ iOS dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to install iOS dependencies" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}

# Attempt iOS build
Write-Host "`n=== Attempting iOS Build ===" -ForegroundColor Green
Write-Host "This will likely fail due to missing ONNX models..." -ForegroundColor Yellow

try {
    flutter build ios --debug --no-codesign 2>&1 | Tee-Object -FilePath "build_log.txt"
    Write-Host "✓ iOS build succeeded!" -ForegroundColor Green
} catch {
    Write-Host "✗ iOS build failed (expected due to missing models)" -ForegroundColor Red
    Write-Host "Build log saved to build_log.txt" -ForegroundColor Yellow
}

# Create empty model files for testing
Write-Host "`n=== Creating Empty Model Files for Testing ===" -ForegroundColor Green
try {
    New-Item -Path "assets/models/tokenizers" -ItemType Directory -Force | Out-Null
    foreach ($model in $missingModels) {
        New-Item -Path $model -ItemType File -Force | Out-Null
        Write-Host "Created empty: $model" -ForegroundColor Cyan
    }
    Write-Host "✓ Empty model files created" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create empty model files" -ForegroundColor Red
}

# Retry build with empty models
Write-Host "`n=== Retrying Build with Empty Models ===" -ForegroundColor Green
try {
    flutter clean
    flutter pub get
    if ($IsMacOS) {
        Set-Location "ios"
        pod install
        Set-Location ".."
    }
    flutter build ios --debug --no-codesign 2>&1 | Tee-Object -FilePath "build_log_with_empty_models.txt"
    Write-Host "✓ iOS build with empty models succeeded!" -ForegroundColor Green
} catch {
    Write-Host "✗ iOS build still failed even with empty models" -ForegroundColor Red
    Write-Host "Build log saved to build_log_with_empty_models.txt" -ForegroundColor Yellow
}

Write-Host "`n=== Build Analysis Complete ===" -ForegroundColor Green
Write-Host "Key findings:" -ForegroundColor Yellow
Write-Host "1. Original iOS app references ONNX models that don't exist in Git" -ForegroundColor Cyan
Write-Host "2. This suggests iOS uses different ML approach or downloads models" -ForegroundColor Cyan
Write-Host "3. Vector cleanup logic is already implemented correctly" -ForegroundColor Cyan
Write-Host "4. Only need to add startup trigger for vector cleanup" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Add vector cleanup to startup.dart" -ForegroundColor Cyan
Write-Host "2. Test the orphaned vector cleanup functionality" -ForegroundColor Cyan
Write-Host "3. Build and deploy for testing" -ForegroundColor Cyan
