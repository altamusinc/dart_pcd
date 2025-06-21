import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

enum PCDFieldType {
  int, // Integer
  unsignedInt, // Unsigned Integer
  float; // Float

  @override
  String toString() {
    switch (this) {
      case PCDFieldType.int:
        return "I";
      case PCDFieldType.unsignedInt:
        return "U";
      case PCDFieldType.float:
        return "F";
    }
  }
}

enum PCDFieldLength {
  one, // 1 byte
  two, // 2 bytes
  four, // 4 bytes
  eight; // 8 bytes

  int get size {
    switch (this) {
      case PCDFieldLength.one:
        return 1;
      case PCDFieldLength.two:
        return 2;
      case PCDFieldLength.four:
        return 4;
      case PCDFieldLength.eight:
        return 8;
    }
  }

  @override
  String toString() {
    switch (this) {
      case PCDFieldLength.one:
        return "1";
      case PCDFieldLength.two:
        return "2";
      case PCDFieldLength.four:
        return "4";
      case PCDFieldLength.eight:
        return "8";
    }
  }
}

enum PCDDataType {
  ascii, // ASCII format
  binary, // Binary format
  binaryCompressed; // Compressed binary format

  @override
  String toString() {
    switch (this) {
      case PCDDataType.ascii:
        return "ascii";
      case PCDDataType.binary:
        return "binary";
      case PCDDataType.binaryCompressed:
        return "binary_compressed";
    }
  }
}

class PCD {
  List<List<num>> points;
  late PCDHeader header;


  // Feed XYZ points, expects points to be 3 values long, errors if not. Autodetects float or int and assumes 4 bytes for each.
  PCD.fromXYZPoints(this.points)
  {
    if (points.isEmpty || points[0].length != 3) {
      throw Exception("Points must be a list of lists with exactly 3 values each.");
    }
    var fields = ["x", "y", "z"];
    var sizes = List.filled(3, PCDFieldLength.four);
    var types = detectDataTypeFromPoint(points[0]);
    if (types.length != 3) {
      throw Exception("Detected types do not match expected number of fields.");
    }
    header = PCDHeader(fields, sizes, types, points.length, 1, points.length);
  }

  
  // Feed XYZI points, expects points to be 4 values long, errors if not. Autodetects float or int and assumes 4 bytes for each.
  PCD.fromXYZIPoints(this.points)
  {
    if (points.isEmpty || points[0].length != 4) {
      throw Exception("Points must be a list of lists with exactly 4 values each.");
    }
    var fields = ["x", "y", "z", "intensity"];
    var sizes = List.filled(4, PCDFieldLength.four);
    var types = detectDataTypeFromPoint(points[0]);
    if (types.length != 4) {
      throw Exception("Detected types do not match expected number of fields.");
    }
    header = PCDHeader(fields, sizes, types, points.length, 1, points.length);
  }

  // Roll your own; feed points, field names, and datatypes
  PCD.fromPoints({required this.points, required List<String> fieldNames, required List<PCDFieldType> fieldTypes, required List<PCDFieldLength> fieldLengths})
  {
    if (points.isEmpty) {
      throw Exception("Points must not be empty.");
    }
    if (!(fieldNames.length == fieldTypes.length && fieldNames.length == fieldLengths.length)) {
      throw Exception("Field names, types, and lengths must all have the same length.");
    }
    if (fieldNames.length != points[0].length) {
      throw Exception("Points must have same number of fields as field names.");
    }
    
    header = PCDHeader(fieldNames, fieldLengths, fieldTypes, points.length, 1, points.length);
  }

  List<PCDFieldType> detectDataTypeFromPoint(List<num> point) {
    List<PCDFieldType> types = [];
    for (final field in point) {
      if (field is int) {
        types.add(PCDFieldType.int);
      } else if (field is double) {
        types.add(PCDFieldType.float);
      } else {
        throw Exception("Unsupported data type: ${field.runtimeType}");
      }
    }
    return types;
  }

  ByteData pointsToBinary() {
    int pointBytesSize = 0;
    for (var field in header.size) {
      pointBytesSize += field.size; // Calculate total size of a point based on field sizes.
    }
    var bdata = ByteData(pointBytesSize * points.length); // Create a ByteData buffer for all points.
    int offset = 0; // Offset to write into the ByteData buffer.
    for (final point in points) {
      for (var i = 0; i < point.length; i++) {
        var field = point[i];
        var type = header.type[i];
        var size = header.size[i].size;
        switch (type) {
          case PCDFieldType.int:
            switch (size) {
              case 1:
                bdata.setInt8(offset, field.toInt()); // Write as int8.
                break;
              case 2:
                bdata.setInt16(offset, field.toInt(), Endian.little); // Write as int16.
                break;
              case 4:
                bdata.setInt32(offset, field.toInt(), Endian.little); // Write as int32.
                break;
              case 8:
                bdata.setInt64(offset, field.toInt(), Endian.little); // Write as int64.
                break;
            }
            break;
          case PCDFieldType.unsignedInt:
          switch (size) {
              case 1:
                bdata.setUint8(offset, field.toInt() & 0xFF); // Write as uint8.
                break;
              case 2:
                bdata.setUint16(offset, field.toInt() & 0xFFFF, Endian.little); // Write as uint16.
                break;
              case 4:
                bdata.setUint32(offset, field.toInt() & 0xFFFFFFFF, Endian.little); // Write as uint32.
                break;
              case 8:
                bdata.setUint64(offset, field.toInt() & 0xFFFFFFFFFFFFFFFF, Endian.little); // Write as uint64.
                break;
            }
            break;
          case PCDFieldType.float:
            switch (size) {
              case 1:
                throw Exception("Float cannot be 1 byte, use int or unsigned int instead.");
              case 2:
                throw Exception("Float cannot be 2 bytes, use int or unsigned int instead.");
              case 4:
                bdata.setFloat32(offset, field.toDouble(), Endian.little); // Write as float32.
                break;
              case 8:
                bdata.setFloat64(offset, field.toDouble(), Endian.little); // Write as float64.
                break;
            }
            break;
        }
        offset += size; // Move the offset forward by the size of the field.
      }
    }
    return bdata;
  }

  /// Converts a point field to the appropriate data type based on the PCDFieldType.
  dynamic _convertPointFieldToDataType(num field, PCDFieldType type) {
    switch (type) {
      case PCDFieldType.int:
        return field.toInt();
      case PCDFieldType.unsignedInt:
        return field.toInt() & 0xFFFFFFFF; // Ensure unsigned int
      case PCDFieldType.float:
        return field.toDouble();
    }
  }

  ByteData pcdBinary() {
    header.dataType = PCDDataType.binary; // Set the data type in the header to binary.
    String headerString = header.toString(); // Get the header string.
    ByteData headerBytes = ByteData.view(utf8.encode(headerString).buffer); // Convert header string to bytes.
    ByteData pointsBytes = pointsToBinary(); // Convert points to binary format.
    int totalSize = headerBytes.lengthInBytes + pointsBytes.lengthInBytes; // Calculate total size.
    ByteData pcdData = ByteData(totalSize); // Create a ByteData buffer for the PCD data.
    int offset = 0; // Offset to write into the ByteData buffer.
    // Write header bytes into the PCD data.
    for (int i = 0; i < headerBytes.lengthInBytes; i++) {
      pcdData.setUint8(offset++, headerBytes.getUint8(i));
    }
    // Write points bytes into the PCD data.
    for (int i = 0; i < pointsBytes.lengthInBytes; i++) {
      pcdData.setUint8(offset++, pointsBytes.getUint8(i));
    }
    return pcdData; // Return the complete PCD data.
  }

  void saveToFile(
    String filePath, {
    PCDDataType dataType = PCDDataType.binary,
  }) {
    final file = File(filePath);
    file.createSync(recursive: true); // Create the file if it doesn't exist.

    switch (dataType) {
      case PCDDataType.binary:
        file.writeAsBytesSync(pcdBinary().buffer.asUint8List());
        break;
      case PCDDataType.ascii:
        header.dataType = PCDDataType.ascii; // Set the data type in the header.
        file.writeAsStringSync(toString());
        break;
      case PCDDataType.binaryCompressed:
        throw Exception("Binary compressed format is not supported yet.");
    }
  }

  @override
  String toString(){
    String s = "";
    s += header.toString(); // Start with the header string.
    for(final point in points)
    {
      for (var i = 0; i < point.length; i++) {
        var val = _convertPointFieldToDataType(point[i], header.type[i]); // Convert each point value to the correct type.
        s += "${val.toString()} "; // Add each value in the point to the string.
      }
      s += "\n"; // New line after each point.
    }
    return s;
  }
}

class PCDHeader {
  String _comments = "";
  final String _fixedComment = "Generated by dart_pcd on ${DateTime.now()}";
  String version = ".7";
  List<String> fields;
  List<PCDFieldLength> size;
  List<PCDFieldType> type;
  List<num> count;
  int width;
  int height;
  List<int> viewpoint = [0, 0, 0, 1, 0, 0, 0];
  int points;
  PCDDataType dataType = PCDDataType.ascii;
  PCDHeader(
    this.fields,
    this.size,
    this.type,
    this.width,
    this.height,
    this.points,
  ) : count = List<int>.filled(fields.length, 1);

  void addComment(String comment) {
    _comments += comment;
  }

  void clearComments() {
    _comments = "";
  }

  String _buildComments() {
    String commentsStr = "";
    if (_comments.isNotEmpty) {
      var commentLines = _comments.split('\n');
      for (final line in commentLines) {
        commentsStr += "# $line\n";
      }
    }

    commentsStr += "# $_fixedComment";
    return commentsStr;
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

    String comments = _buildComments();
    String s = '''
$comments
VERSION $version
FIELDS $fieldsStr
SIZE $sizeStr
TYPE $typeStr
COUNT $countStr
WIDTH $width
HEIGHT $height
VIEWPOINT $viewpointStr
POINTS $points
DATA $dataType\n''';
    return s;
  }
}
