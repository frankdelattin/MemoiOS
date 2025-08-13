# iOS Runtime Testing Script
# This script helps us understand the actual iOS app runtime behavior

Write-Host "=== MemoIOS Runtime Behavior Analysis ===" -ForegroundColor Green

# 1. Check what models are actually in the assets
Write-Host "`n1. Checking assets/models directory..." -ForegroundColor Yellow
if (Test-Path "assets/models") {
    Get-ChildItem -Path "assets/models" -Recurse | ForEach-Object {
        $size = if ($_.PSIsContainer) { "DIR" } else { "$([math]::Round($_.Length/1KB, 2)) KB" }
        Write-Host "  $($_.FullName.Replace((Get-Location).Path, '.')): $size"
    }
} else {
    Write-Host "  assets/models directory does not exist"
}

# 2. Analyze the startup sequence
Write-Host "`n2. Analyzing app startup sequence..." -ForegroundColor Yellow
if (Test-Path "lib/startup.dart") {
    Write-Host "  Found startup.dart - checking initialization order:"
    Select-String -Path "lib/startup.dart" -Pattern "(await|\.init|Service|Repository)" | ForEach-Object {
        Write-Host "    Line $($_.LineNumber): $($_.Line.Trim())"
    }
}

# 3. Check ONNX service implementation
Write-Host "`n3. Analyzing ONNX Runtime Service..." -ForegroundColor Yellow
if (Test-Path "lib/services/onnx_runtime_service.dart") {
    Write-Host "  Checking model loading patterns:"
    Select-String -Path "lib/services/onnx_runtime_service.dart" -Pattern "(loadModel|encodeImage|encodeText|assets/models)" | ForEach-Object {
        Write-Host "    Line $($_.LineNumber): $($_.Line.Trim())"
    }
}

# 4. Check for iOS-specific implementations
Write-Host "`n4. Looking for iOS-specific code..." -ForegroundColor Yellow
$iosFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Where-Object { $_.Name -match "ios" }
if ($iosFiles) {
    Write-Host "  Found iOS-specific files:"
    $iosFiles | ForEach-Object { Write-Host "    $($_.FullName)" }
} else {
    Write-Host "  No iOS-specific Dart files found"
}

# 5. Check pubspec.yaml for iOS-specific dependencies
Write-Host "`n5. Checking iOS-specific dependencies..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host "  Looking for iOS-specific or ML-related dependencies:"
    Select-String -Path "pubspec.yaml" -Pattern "(ios|onnx|ml|core_ml|vision)" | ForEach-Object {
        Write-Host "    Line $($_.LineNumber): $($_.Line.Trim())"
    }
}

# 6. Check for platform-specific code
Write-Host "`n6. Checking for platform-specific implementations..." -ForegroundColor Yellow
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "Platform\.isIOS|defaultTargetPlatform.*iOS|kIsWeb.*false") {
        Write-Host "  Found platform checks in: $($_.Name)"
        Select-String -Path $_.FullName -Pattern "(Platform\.isIOS|defaultTargetPlatform|kIsWeb)" | ForEach-Object {
            Write-Host "    Line $($_.LineNumber): $($_.Line.Trim())"
        }
    }
}

# 7. Build and run in iOS Simulator for testing
Write-Host "`n7. Testing iOS Simulator build..." -ForegroundColor Yellow
Write-Host "  Checking Flutter installation..."
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Flutter found - attempting iOS Simulator build"
        Write-Host "  Running: flutter build ios --simulator --debug"
        
        # Create empty model files first
        if (!(Test-Path "assets/models")) {
            New-Item -ItemType Directory -Path "assets/models/tokenizers" -Force
            New-Item -ItemType File -Path "assets/models/nlp_visualize_opset3.onnx" -Force
            New-Item -ItemType File -Path "assets/models/nlp_textual_opset3.onnx" -Force
            New-Item -ItemType File -Path "assets/models/tokenizers/nlp_textual_tokenizer.txt.gz" -Force
            Write-Host "  Created empty model files for testing"
        }
        
        flutter clean
        flutter pub get
        flutter build ios --simulator --debug
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ iOS Simulator build successful!" -ForegroundColor Green
            Write-Host "  You can now run: flutter run -d 'iOS Simulator' to test runtime behavior"
        } else {
            Write-Host "  ❌ iOS Simulator build failed" -ForegroundColor Red
        }
    } else {
        Write-Host "  Flutter not found in PATH - skipping build test"
    }
} catch {
    Write-Host "  Error checking Flutter: $($_.Exception.Message)"
}

Write-Host "`n=== Analysis Complete ===" -ForegroundColor Green
Write-Host "This analysis helps us understand:" -ForegroundColor Cyan
Write-Host "1. What model files actually exist vs. what code expects"
Write-Host "2. The app startup and initialization sequence"
Write-Host "3. Whether there are iOS-specific implementations"
Write-Host "4. Platform-specific code paths that might bypass ONNX"
Write-Host "5. Whether the app can run in iOS Simulator for testing"
