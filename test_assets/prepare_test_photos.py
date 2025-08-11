#!/usr/bin/env python3
"""
Test Photo Dataset Generator for Vector Cleanup Testing
Creates a set of test photos with metadata for emulator injection
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path

def create_test_dataset():
    """Create test photo dataset for vector cleanup validation."""
    
    print("📸 CREATING TEST PHOTO DATASET")
    print("=" * 40)
    
    # Create test assets directory
    assets_dir = Path("test_assets")
    assets_dir.mkdir(exist_ok=True)
    
    # Test scenario configuration
    test_scenarios = {
        "scenario_1_baseline": {
            "description": "Initial photo set - all photos should have vectors",
            "photos": [
                {"id": "photo_001", "name": "sunset_beach.jpg", "size": "1920x1080", "date": "2024-01-15"},
                {"id": "photo_002", "name": "mountain_hike.jpg", "size": "1920x1080", "date": "2024-01-16"},
                {"id": "photo_003", "name": "city_skyline.jpg", "size": "1920x1080", "date": "2024-01-17"},
                {"id": "photo_004", "name": "forest_path.jpg", "size": "1920x1080", "date": "2024-01-18"},
                {"id": "photo_005", "name": "ocean_waves.jpg", "size": "1920x1080", "date": "2024-01-19"},
            ]
        },
        "scenario_2_deletions": {
            "description": "After deleting photos 2 and 4 from gallery",
            "photos": [
                {"id": "photo_001", "name": "sunset_beach.jpg", "size": "1920x1080", "date": "2024-01-15"},
                {"id": "photo_003", "name": "city_skyline.jpg", "size": "1920x1080", "date": "2024-01-17"},
                {"id": "photo_005", "name": "ocean_waves.jpg", "size": "1920x1080", "date": "2024-01-19"},
            ],
            "deleted_photos": ["photo_002", "photo_004"],
            "expected_orphaned_vectors": ["photo_002", "photo_004"]
        },
        "scenario_3_mixed": {
            "description": "After adding new photos and deleting one more",
            "photos": [
                {"id": "photo_001", "name": "sunset_beach.jpg", "size": "1920x1080", "date": "2024-01-15"},
                {"id": "photo_003", "name": "city_skyline.jpg", "size": "1920x1080", "date": "2024-01-17"},
                {"id": "photo_006", "name": "lake_reflection.jpg", "size": "1920x1080", "date": "2024-01-20"},
                {"id": "photo_007", "name": "desert_sunset.jpg", "size": "1920x1080", "date": "2024-01-21"},
            ],
            "deleted_photos": ["photo_002", "photo_004", "photo_005"],
            "expected_orphaned_vectors": ["photo_005"]  # photo_002, photo_004 already cleaned
        }
    }
    
    # Save test scenarios
    scenarios_file = assets_dir / "test_scenarios.json"
    with open(scenarios_file, 'w') as f:
        json.dump(test_scenarios, f, indent=2)
    
    print(f"✅ Test scenarios saved to: {scenarios_file}")
    
    # Create test execution plan
    execution_plan = {
        "test_execution_steps": [
            {
                "step": 1,
                "action": "inject_initial_photos",
                "scenario": "scenario_1_baseline",
                "description": "Inject 5 initial photos into iOS simulator gallery",
                "validation": [
                    "Launch app and verify startup completes",
                    "Check console logs for vector generation",
                    "Verify 5 vectors created in database",
                    "Test search functionality works"
                ]
            },
            {
                "step": 2,
                "action": "delete_photos_from_gallery",
                "scenario": "scenario_2_deletions", 
                "description": "Delete photos 2 and 4 from iOS Photos app",
                "validation": [
                    "Delete photo_002 and photo_004 from iOS Photos",
                    "Force-close the app completely",
                    "Relaunch app to trigger vector cleanup",
                    "Check console logs for cleanup activity",
                    "Verify orphaned vectors are removed",
                    "Test search - should not return deleted photos"
                ]
            },
            {
                "step": 3,
                "action": "mixed_operations",
                "scenario": "scenario_3_mixed",
                "description": "Add new photos and delete one more",
                "validation": [
                    "Add photo_006 and photo_007 to gallery",
                    "Delete photo_005 from gallery", 
                    "Restart app to trigger cleanup",
                    "Verify only photo_005 vector is cleaned (others already cleaned)",
                    "Verify new photos generate vectors",
                    "Test comprehensive search functionality"
                ]
            }
        ],
        "success_criteria": {
            "startup_performance": "App starts within 5 seconds",
            "cleanup_performance": "Vector cleanup completes within 2 seconds",
            "search_accuracy": "Search returns only existing photos",
            "no_crashes": "App remains stable throughout testing",
            "console_logging": "Clear logs show cleanup operations"
        }
    }
    
    # Save execution plan
    plan_file = assets_dir / "test_execution_plan.json"
    with open(plan_file, 'w') as f:
        json.dump(execution_plan, f, indent=2)
    
    print(f"✅ Test execution plan saved to: {plan_file}")
    
    # Create photo injection instructions
    injection_instructions = """
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
"""
    
    instructions_file = assets_dir / "photo_injection_instructions.md"
    with open(instructions_file, 'w') as f:
        f.write(injection_instructions)
    
    print(f"✅ Photo injection instructions saved to: {instructions_file}")
    
    # Create test validation checklist
    checklist = {
        "pre_test_checklist": [
            "☐ Cloud emulator service account created",
            "☐ iOS simulator selected (iOS 15+ recommended)",
            "☐ Test photos prepared and accessible",
            "☐ App successfully uploaded to testing platform",
            "☐ Console logging enabled for debugging"
        ],
        "during_test_checklist": [
            "☐ Record screen for documentation",
            "☐ Monitor console logs in real-time", 
            "☐ Take screenshots at each validation step",
            "☐ Note performance metrics (startup time, cleanup time)",
            "☐ Test search functionality after each scenario"
        ],
        "post_test_checklist": [
            "☐ Download console logs",
            "☐ Save screen recordings",
            "☐ Document any issues or unexpected behavior",
            "☐ Verify all success criteria met",
            "☐ Prepare test report"
        ]
    }
    
    checklist_file = assets_dir / "test_validation_checklist.json"
    with open(checklist_file, 'w') as f:
        json.dump(checklist, f, indent=2)
    
    print(f"✅ Test validation checklist saved to: {checklist_file}")
    
    print("\n🎯 TEST DATASET CREATION COMPLETE!")
    print("=" * 40)
    print("Files created:")
    print(f"  📋 {scenarios_file}")
    print(f"  📋 {plan_file}")
    print(f"  📋 {instructions_file}")
    print(f"  📋 {checklist_file}")
    print("\nNext: Download test photos and proceed to cloud emulator setup!")

if __name__ == "__main__":
    create_test_dataset()
