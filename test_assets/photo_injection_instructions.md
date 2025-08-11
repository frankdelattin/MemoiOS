
# iOS Simulator Photo Injection Instructions

## Method 1: Drag & Drop (Easiest)
1. Open iOS Simulator
2. Open Photos app in simulator
3. Drag test photos from your computer directly into the Photos app
4. Photos will be automatically added to the gallery

## Method 2: Simulator Menu
1. In iOS Simulator, go to Device > Photos
2. Select "Add Photos..."
3. Choose test photos from test_assets/photos/ directory

## Method 3: Xcode Organizer (Advanced)
1. Open Xcode
2. Go to Window > Devices and Simulators
3. Select your simulator
4. Use "Add Photos" button in Installed Apps section

## Test Photo Requirements
- Use photos with minimum 224x224 resolution (app filter requirement)
- Include EXIF metadata for realistic testing
- Use JPEG format for compatibility
- Ensure photos have unique identifiers

## Validation Commands
After each step, check these in Xcode console:
- Look for "Starting orphaned vector cleanup..."
- Look for "Cleaned up X orphaned vectors"
- Look for "No orphaned vectors found" (when expected)
