import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class StorageTestWidget extends StatefulWidget {
  const StorageTestWidget({Key? key}) : super(key: key);

  @override
  State<StorageTestWidget> createState() => _StorageTestWidgetState();
}

class _StorageTestWidgetState extends State<StorageTestWidget> {
  bool _isTesting = false;
  String _testResult = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _runStorageTest() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Running storage test...';
    });

    try {
      // Test 1: Check storage configuration
      _testResult += '\n1. Checking storage configuration...';
      await SupabaseService.checkStorageConfiguration();
      _testResult += '\n✓ Storage configuration checked';

      // Test 2: Try to pick an image
      _testResult += '\n2. Testing image picker...';
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        _testResult += '\n✗ No image selected';
        setState(() => _isTesting = false);
        return;
      }
      _testResult += '\n✓ Image selected: ${image.name}';

      // Test 3: Try to upload image (this will fail without a real product, but we can test the URL generation)
      _testResult += '\n3. Testing media URL generation...';
      final testFileName = 'test_image.jpg';
      final testUrl = await SupabaseService.testMediaUrl(testFileName);
      _testResult += '\n✓ Test URL generated: $testUrl';

      _testResult += '\n\n✅ All tests completed successfully!';
      _testResult += '\n\nIf images are still not displaying:';
      _testResult += '\n- Check if the products bucket exists in Supabase';
      _testResult += '\n- Verify bucket permissions (should be public)';
      _testResult += '\n- Check if media records exist in product_media table';
      _testResult += '\n- Verify media URLs are valid and accessible';
    } catch (e) {
      _testResult += '\n\n❌ Test failed: $e';
      _testResult += '\n\nPossible issues:';
      _testResult += '\n- Supabase storage bucket not configured';
      _testResult += '\n- Storage permissions not set correctly';
      _testResult += '\n- Network connectivity issues';
      _testResult += '\n- Authentication issues';
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _runStorageTest,
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Run Storage Test'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(_testResult),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to test storage from anywhere
Future<void> runStorageTest(BuildContext context) async {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const StorageTestWidget()),
  );
}
