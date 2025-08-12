import 'package:EcoMap/models/waste_bin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'waste_bin_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('WasteBin Model Tests', () {
    test('should create WasteBin from Firestore document', () {
      // Arrange
      final mockDoc = MockDocumentSnapshot();
      final data = {
        'name': 'Test Bin',
        'description': 'Test Description',
        'location': const GeoPoint(48.8566, 2.3522),
        'type': 'general',
        'status': 'available',
        'addedBy': 'test_user',
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        'usageCount': 5,
      };

      when(mockDoc.id).thenReturn('test_id');
      when(mockDoc.data()).thenReturn(data);

      // Act
      final wasteBin = WasteBin.fromFirestore(mockDoc);

      // Assert
      expect(wasteBin.id, equals('test_id'));
      expect(wasteBin.name, equals('Test Bin'));
      expect(wasteBin.description, equals('Test Description'));
      expect(wasteBin.type, equals('general'));
      expect(wasteBin.status, equals('available'));
      expect(wasteBin.usageCount, equals(5));
    });

    test('should convert WasteBin to Firestore map', () {
      // Arrange
      const testId = 'test_bin_1';
      final wasteBin = WasteBin(
        id: testId,
        name: 'Test Bin',
        description: 'Test Description',
        location: const LatLng(48.8566, 2.3522),
        type: 'recyclable',
        status: 'available',
        addedBy: 'test_user',
        createdAt: DateTime(2024, 1, 1),
        lastUpdated: DateTime(2024, 1, 1),
        usageCount: 0,
      );

      // Act
      final map = wasteBin.toFirestore();

      // Assert
      expect(map['name'], equals('Test Bin'));
      expect(map['description'], equals('Test Description'));
      expect(map['type'], equals('recyclable'));
      expect(map['status'], equals('available'));
      expect(map['usageCount'], equals(0));
    });

    test('should create copy with updated values', () {
      // Arrange
      const testId = 'test_bin_2';
      final original = WasteBin(
        id: testId,
        name: 'Original Bin',
        description: 'Original Description',
        location: const LatLng(48.8566, 2.3522),
        type: 'general',
        status: 'available',
        addedBy: 'test_user',
        createdAt: DateTime(2024, 1, 1),
        lastUpdated: DateTime(2024, 1, 1),
        usageCount: 0,
      );

      // Act
      final updated = original.copyWith(
        name: 'Updated Bin',
        usageCount: 10,
      );

      // Assert
      expect(updated.id, equals(testId)); // ID should remain the same
      expect(updated.name, equals('Updated Bin'));
      expect(updated.usageCount, equals(10));
      expect(updated.description, equals('Original Description')); // Unchanged
      expect(updated.type, equals('general')); // Unchanged
    });

    test('should handle empty description', () {
      // Arrange
      const testId = 'test_bin_3';
      final wasteBin = WasteBin(
        id: testId,
        name: 'Test Bin',
        description: '',
        location: const LatLng(48.8566, 2.3522),
        type: 'general',
        status: 'available',
        addedBy: 'test_user',
        createdAt: DateTime(2024, 1, 1),
        lastUpdated: DateTime(2024, 1, 1),
        usageCount: 0,
      );

      // Act & Assert
      expect(wasteBin.description, equals(''));
      expect(wasteBin.description!.isEmpty, isTrue);
    });
  });
}
