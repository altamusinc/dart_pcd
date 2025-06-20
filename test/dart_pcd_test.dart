import 'package:dart_pcd/dart_pcd.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final xyzPoints = [
      [1.0, 2, 3.0],
      [4.0, 5, 6.0],
      [7.0, 8, 9.0],
      [4.0, 5, 6.0],
      [4.0, 5, 6.0],
      [7.0, 8, 9.0],
      [7.0, 8, 9.0],
      [4.0, 5, 6.0],
      [7.0, 8, 9.0],
    ];

    final xyziPoints = [
      [1.0, 2.0, 3.0, 0.5],
      [4.0, 5.0, 6.0, 1.5],
      [7.0, 8.0, 9.0, 2.5],
      [4.0, 5.0, 6.0, 3.5],
      [4.0, 5.0, 6.0, 4.5],
      [7.0, 8.0, 9.0, 5.5],
      [7.0, 8.0, 9.0, 6.5],
      [4.0, 5.0, 6.0, 7.5],
      [7.0, 8.0, 9.0, 8.5],
    ];

    final xyzdiatPoints = [
      [1, 2.0, 3.0, 0.5, 1.0, 10, 100.0],
      [4, 5.0, 6.0, 1.5, 2.0, 10, 100.0],
      [7, 8.0, 9.0, 2.5, 3.0, 10, 100.0],
      [4, 5.0, 6.0, 3.5, 4.0, 10, 100.0],
      [4, 5.0, 6.0, 4.5, 5.0, 10, 100.0],
      [7, 8.0, 9.0, 5.5, 6.0, 10, 100.0],
      [7, 8.0, 9.0, 6.5, 7.0, 10, 100.0],
      [4, 5.0, 6.0, 7.5, 8.0, 10, 100.0],
      [7, 8.0, 9.0, 8.5, 9.0, 10, 100.0],
    ];


    setUp(() {
      // Additional setup goes here.
    });

    test('XYZ Points', () {
      var pcd = PCD.fromXYZPoints(xyzPoints);
      String comment = '''
this is a test comment
i'm including multiple lines
{JSON: "test": "comment"}
''';
      print(pcd.header);
      pcd.header.addComment(comment);
      print(pcd.header);
      expect(pcd.points.length, 9);
    });

    test('XYZI Points', () {
      final pcd = PCD.fromXYZIPoints(xyziPoints);
      expect(pcd.points.length, 9);
    });

    test("Custom Point format", () {
      var fieldNames = ["x", "y", "z", "distance", "intensity", "alpha", "theta"];
      var fieldSizes = [PCDFieldLength.four, PCDFieldLength.four, PCDFieldLength.four, PCDFieldLength.two, PCDFieldLength.two, PCDFieldLength.two, PCDFieldLength.two];
      var fieldTypes = [PCDFieldType.float, PCDFieldType.float, PCDFieldType.float, PCDFieldType.unsignedInt, PCDFieldType.unsignedInt, PCDFieldType.unsignedInt, PCDFieldType.unsignedInt];
      final pcd = PCD.fromPoints(points: xyzdiatPoints, fieldNames: fieldNames, fieldTypes: fieldTypes, fieldLengths: fieldSizes);
      print(pcd);
      expect(pcd.points.length, 9);
    });
  });
}
