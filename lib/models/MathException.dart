class MathException implements Exception{
  final String message;
  final Code code;

  MathException(this.message , {this.code});

  String toString(){
    return this.message;
  }

}

enum Code {
  Empty,
  NaN,
  Inifinity,
}