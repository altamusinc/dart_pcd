import 'package:dart_pcd/dart_pcd.dart';

void main() {
  List<List<num>> points = [];
  points.add([1, 2.0, 3]);
  points.add([4, 5.0, 6]);
  points.add([7, 8.0, 9]);
  var pcd = PCD(points);
  print(pcd);
}
