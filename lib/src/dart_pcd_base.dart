import 'dart:ffi';
import 'dart:typed_data';
class PCD {
  List<String>? fields;
  List<List<num>> points;
  late PCDHeader header;
  List<int> validSizes = [1,2,4,8];
  List<String> validTypes = ["I", "U", "F"];


  // Feed XYZ points, expects points to be 3 values long, errors if not. Autodetects float or int and assumes 4 bytes for each.
  PCD.fromXYZPoints(this.points)
  {
    
  }

  
  // Feed XYZI points, expects points to be 4 values long, errors if not. Autodetects float or int and assumes 4 bytes for each.
  PCD.fromXYZIPoints(this.points)
  {

  }

  // Roll your own; feed points, field names, and datatypes
  PCD.fromPoints(this.points, this.fields, List<Type> dataTypes)
  {

  }

  // Generate a header from an example point. Assumes all other points are the same shape/type
  PCDHeader _makeHeaderFromPoints(List<num> point)
  {
    List<int> size = [];
    List<String> type = [];

    for (final field in point) {
      switch (field) {
        case int():
          print("int!");
          type.add("I");
          size.add(4);
        case double():
          print("double");
          type.add("F");
          size.add(4);
      }
    }

    return PCDHeader(fields, size, type, width, height, points, data)
  }

  @override
  String toString(){
    String s = header.toString();
    for(final point in points)
    {
      String p = ""; // String for the row representing this point
      for (final field in point)
      {
        p += "${field.toString()} "; // fill out the row
      }
      s += "${p.trim()} \n"; // Add it to the string.
    }
    return s;
  }
}

class PCDHeader {
  String version = "0.7";
  List<String> fields;
  List<int> size;
  List<String> type;
  late List<num> count;
  int width;
  int height;
  List<int> viewpoint = [0, 0, 0, 1, 0, 0, 0];
  int points;
  String data;
  PCDHeader(
    this.fields,
    this.size,
    this.type,
    this.width,
    this.height,
    this.points,
    this.data,
  ) {
    count = [];
    for (var _ in fields) {
      count.add(1);
    }
  }

  @override
  String toString() {
    String fieldsStr = "";
    for (final field in fields) {
      fieldsStr += "$field ";
    }
    String sizeStr = "";
    for (final s in size) {
      sizeStr += "${s.toString().trim()} ";
    }
    String typeStr = "";
    for (final t in type) {
      typeStr += "$t ";
    }
    String countStr = "";
    for (final c in count) {
      countStr += "${c.toString()} ";
    }
    String viewpointStr = "";
    for (final v in viewpoint) {
      viewpointStr += "${v.toString()} ";
    }

    String s = '''
VERSION $version
FIELDS $fieldsStr
SIZE $sizeStr
TYPE $typeStr
COUNT $countStr
WIDTH $width
HEIGHT $height
VIEWPOINT $viewpointStr
POINTS $points
DATA $data\n''';
    return s;
  }
}
