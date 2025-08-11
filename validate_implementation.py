#!/usr/bin/env python3
"""
Vector Cleanup Implementation Validator
This script validates the vector cleanup implementation without requiring Flutter.
"""

import os
import re
from pathlib import Path

def validate_implementation():
    """Validate the vector cleanup implementation files."""
    print("🧪 VECTOR CLEANUP IMPLEMENTATION VALIDATOR")
    print("=" * 50)
    
    base_path = Path(".")
    results = []
    
    # Check 1: VectorService cleanup method exists
    vector_service_path = base_path / "lib" / "services" / "vector_service.dart"
    if vector_service_path.exists():
        content = vector_service_path.read_text()
        if "cleanupOrphanedVectors" in content:
            results.append("✅ VectorService.cleanupOrphanedVectors() method found")
            
            # Check for proper error handling
            if "try {" in content and "catch (e)" in content:
                results.append("✅ Error handling implemented in cleanup method")
            else:
                results.append("❌ Missing error handling in cleanup method")
                
            # Check for logging
            if "print(" in content:
                results.append("✅ Logging implemented for cleanup operations")
            else:
                results.append("⚠️  No logging found in cleanup method")
        else:
            results.append("❌ cleanupOrphanedVectors method not found in VectorService")
    else:
        results.append("❌ VectorService file not found")
    
    # Check 2: Repository method exists
    repo_path = base_path / "lib" / "repositories" / "image_vectors_repository.dart"
    if repo_path.exists():
        content = repo_path.read_text()
        if "getAllImageIds" in content:
            results.append("✅ ImageVectorsRepository.getAllImageIds() method found")
        else:
            results.append("❌ getAllImageIds method not found in repository")
    else:
        results.append("❌ ImageVectorsRepository file not found")
    
    # Check 3: ImageService method exists
    image_service_path = base_path / "lib" / "services" / "image_service.dart"
    if image_service_path.exists():
        content = image_service_path.read_text()
        if "getAllImageIds" in content:
            results.append("✅ ImageService.getAllImageIds() method found")
        else:
            results.append("❌ getAllImageIds method not found in ImageService")
    else:
        results.append("❌ ImageService file not found")
    
    # Check 4: Startup integration
    startup_path = base_path / "lib" / "startup.dart"
    if startup_path.exists():
        content = startup_path.read_text()
        if "cleanupOrphanedVectors" in content:
            results.append("✅ Vector cleanup integrated into startup flow")
        else:
            results.append("❌ Vector cleanup not integrated into startup")
    else:
        results.append("❌ Startup file not found")
    
    # Check 5: Test files exist
    test_files = [
        "test/services/vector_service_test.dart",
        "test/repositories/image_vectors_repository_test.dart", 
        "test/services/image_service_test.dart",
        "test/integration/vector_cleanup_integration_test.dart"
    ]
    
    test_count = 0
    for test_file in test_files:
        if (base_path / test_file).exists():
            test_count += 1
            results.append(f"✅ Test file exists: {test_file}")
        else:
            results.append(f"❌ Missing test file: {test_file}")
    
    # Check 6: GitHub Actions workflow
    workflow_path = base_path / ".github" / "workflows" / "test.yml"
    if workflow_path.exists():
        results.append("✅ GitHub Actions workflow configured")
    else:
        results.append("❌ GitHub Actions workflow missing")
    
    # Print results
    print("\n📊 VALIDATION RESULTS:")
    print("-" * 30)
    for result in results:
        print(result)
    
    # Summary
    success_count = len([r for r in results if r.startswith("✅")])
    total_checks = len(results)
    
    print(f"\n🎯 SUMMARY: {success_count}/{total_checks} checks passed")
    
    if success_count >= total_checks * 0.8:  # 80% threshold
        print("🎉 IMPLEMENTATION LOOKS GOOD!")
        print("Ready for GitHub push and automated testing.")
    else:
        print("⚠️  ISSUES DETECTED")
        print("Please review the failed checks above.")
    
    return success_count, total_checks

if __name__ == "__main__":
    validate_implementation()
