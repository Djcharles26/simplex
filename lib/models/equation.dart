import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Equation {
  Map<String,double> _values;
  List<String> signs;
  String logical;
  double res;
  String variableAction = '';
  bool pivot;
  String name;

  Equation({int variables= 2, bool pivot=false}){
    this._values = new Map();
    this.signs = [];
    this.res = 0.0;
    this.pivot = pivot;
    this.logical = ">=";
    addSign("+", count: 2);
  }

  Equation.full(Map<String,double> values, List<String> signs, logical, {double res = 0.0, pivot = false, name = "", variableAction="NA"}){
    this._values = values; 
    this.logical = logical;
    this.signs = signs;
    this.res = res;
    this.pivot = pivot;
    this.name = name;
    this.variableAction = variableAction;
  }

  factory Equation.from(Equation eq){
    return Equation.full(
      Map<String,double>.from(eq.values),
      List<String>.from(eq.signs),
      eq.logical,
      res: eq.res??0.0,
      name: eq.name,
      variableAction: eq.variableAction
    );
  }
  /// Add Sign to equation array
  /// 
  /// If count is passed, will add that sign 'count' times
  void addSign(String sign ,{count = 1}){
    if(count > 1){
      for(var i=0 ; i<count; i++) signs.add(sign);
      
    }else signs.add(sign);
  }

  /// Remove Last sign in array
  void removeSign(){
    signs.removeLast();
  }

  Map<String,double> get  values => this._values;

  void setValuesMap(Map<String,double>vals){
    this._values = vals;
  }

  /// Remove variable from list
  void removeValue(String name){
    this._values.remove(name);
  }

  void _flipLogical(){
    if(logical == ">=") logical = "<=";
    else if(logical == "<=") logical = ">=";
  }

  /// Convert signs set in input and value
  void convertSigns(){
    for(int i=0; i<signs.length-1; i++){
      int sign = int.parse("${this.signs[i]}1");

      this._values.update(this._values.keys.elementAt(i+1), (value) => value *= sign);
      
    }
  }

  /// Turn signs of equation if needed
  void turnSigns(){
    if(res < 0){
      int sign = -1;
      res *= sign;
      this._values.values.forEach((element) {
        element *= sign;
      });
      _flipLogical();
    }
  }

  /// Pass equation to the other side of the equality
  void flipEquation(){
    for(int i=0; i<this._values.values.length; i++){
      this._values.update(this._values.keys.elementAt(i), (value) => value*-1);
    }
  }

  /// Add an holgura or exceso variable 
  /// 
  /// Variable holgura is default to true
  void addH(int index, double value, {bool holgura = true}){
    if(holgura)  this._values["H$index"] = value;
    else this._values["H$index"] = -value;
  }

  /// Add an artificial Variable
  void addA(int index, double value) {
    this._values["A$index"] = value;
  }

  void setActions(int index, int num1,{int num2}){
    if(this.logical == ">="){
      this.variableAction = "Ya que la restricción $index es del tipo '>=' se agrega la variable de exceso H$num1 y la variable artificial A$num2";
    }else if(this.logical == "<="){
      this.variableAction = "Ya que la restricción $index es del tipo '<=' se agrega la variable de holgura H$num1";
    }else{
      this.variableAction = "Ya que la restricción $index es del tipo '=' se agrega la variable artificial A$num1";
    }
  }

  String _text(List<String> keys, {needInit = false}){
    String func = "";
    bool init = true;
    keys.forEach((key) {
      if(init && needInit){
        func += this._values[key].toString();
        func += key;
        init = false;
      }else {
        if(!this.values[key].toString().contains("-")) func += " +";
        else func += " ";
        func += this.values[key].toString();
        func += key;
      }
    });
    return func;
  }

  String getTableRowName({int pivot: -1}){
    String rowTitle = '';
    if(pivot != -1){
      return this._values.keys.elementAt(pivot);
    }
    if(this._values.keys.firstWhere((element) => element.contains("A"), orElse: ()=> null) != null){
      rowTitle = this._values.keys.firstWhere((element) => element.contains("A"));
    }else{
      rowTitle = this._values.keys.firstWhere((element) => element.contains("H"));
    }
    return rowTitle;
  }

  TableRow toRow(List<String> headers , {bool z= false, int pivot: -1}){
    List<TableCell> cells = [];
    
    cells.add(TableCell(child: Center(child: Text(name, style:TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)))));
    cells.add(TableCell(child: Center(child: Text(z ? "1" : "0", style:TextStyle(fontSize: 16)))));
    
    headers.forEach((header) {

      cells.add(TableCell(child: Center(child: Text(this._values[header] == null ? "0.0" :  this._values[header].toStringAsFixed(2) , style:TextStyle(fontSize: 16)))));
    });
    cells.add(TableCell(child: Center(child: Text(this.res.toStringAsFixed(2), style:TextStyle(fontSize: 16)))));

    return TableRow(
      children: cells,
    );
  }

  TableRow getOutHeader(int variable){
    List<TableCell> cells = [];
    String v = this._values.keys.elementAt(variable);
    cells.add(TableCell(child: Container()));
    cells.add(TableCell(child: Center(child: Text(v, style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),)));
    cells.add(TableCell(child: Center(child: Text("Lado Derecho", style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),))));
    cells.add(TableCell(child: Center(child: Text("Cociente", style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),))));
    return TableRow(children: cells);
  }

  TableRow getOutRow(int variable, {z=false}){
    List<TableCell> cells = [];
    String v = this._values.keys.elementAt(variable);  
    cells.add(TableCell(child: Center(child: Text(name, style:TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)))));

    cells.add(TableCell(child: Center(child: Text(this._values[v].toString(), style:TextStyle(fontSize: 16)))));
    cells.add(TableCell(child: Center(child: Text(this.res.toString(), style:TextStyle(fontSize: 16)))));
    if(!z){

      cells.add(TableCell(child: Center(child: Text(this.res.toString() +   " / " + this._values[v].toString() +
        " = ${(this.res/this._values[v]).toStringAsFixed(2)}",
        style:TextStyle(fontSize: 16))
      )));
    }else cells.add(TableCell(child: Container()));
    return TableRow(children: cells);
  }

  List<String> header(){
    List<String> header = [];
    header.addAll(this.values.keys.where((e)=> e.contains("X")).toList());
    header.addAll(this.values.keys.where((e)=> e.contains("H")).toList());
    header.addAll(this.values.keys.where((e)=> e.contains("A")).toList());
    return header;
  }

  String toString({bool z = false, bool action = true}){
    if(z){
      String func = action ?  "Z" : "G";
      List<String> aux = this.values.keys.where((element) => element.contains("X")).toList();
      func += _text(aux);
      aux = this.values.keys.where((element) => element.contains("H")).toList();
      func += _text(aux);
      aux = this.values.keys.where((element) => element.contains("A")).toList();
      func += _text(aux);
      func += "= 0";
      return func;
    }else{
      String func = "";
      List<String> aux = this.values.keys.where((element) => element.contains("X") ).toList();
      func += _text(aux, needInit: true);
      aux = this.values.keys.where((element) => element.contains("H")).toList();
      func += _text(aux);
      aux = this.values.keys.where((element) => element.contains("A")).toList();
      func += _text(aux);
      func +=" = ${this.res}";
      return func;
    }
  }
}