import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:simplex/models/MathException.dart';
import 'package:simplex/models/equation.dart';

class Simplex extends ChangeNotifier {

  Equation zFunction, newZFunction, faseIFunction, firstFunction = Equation(), updatedFunction = Equation();
  List<Equation> equations, newEquations = new List(), faseEquations = new List(), firstEquations = List(), updatedEquations = new List();
  Equation pivotRow = new Equation(pivot: true);
  bool action = false;
  bool solved = false;
  int variables = 0;
  int varIn = -1, varOut = -1;
  bool optimized = false, faseIOptimized = false, inartificial = false;
  bool requireFases = false;
  List<String> usedVariables = new List();

  void _fillFirstEquations(){
    this.firstFunction = Equation.from(zFunction);
    for(Equation eq in this.equations){
      this.firstEquations.add(Equation.from(eq));
    }
  }

  void printEquations(List<Equation> equations){
    for(Equation eq in equations){
      print(eq.values);
    }
  }

  void processInfo(Equation zFunction, List<Equation> equations, bool action, int variables){
    print("Z function initial values : ${zFunction.values}");
    printEquations(equations);
    _cleanEquations(); //Clean any equation to avoid errors
    
    this.zFunction = Equation.from(zFunction); //Set A clone of zFunction
    if(!action) this.zFunction.flipEquation();
    this.equations = new List(); //Set a clone of equations lists
    for(Equation eq in equations){
      Equation e = new Equation.from(eq);
      this.equations.add(e);
    }
    //Set variables
    this.action = action;
    this.variables = variables;
    try{
      int count = 0;
      //This part should be repeated until all variables are checked and discarded or used to show solution
      
      _checkSigns(); //Check for signs of the equations in course of the ones that are set in form
      _addVariables(); //Add all needed variables
      this.zFunction.flipEquation(); //Flip Z Function signs
      _setRowNames(); //Set all row names
      _fillFirstEquations();
      if(this.requireFases){
          this.faseIFunction = new Equation.from(this.zFunction); //Copy zFunction to manipulate without losing real values
          this.faseIFunction.name = this.action ? "Z" : "G"; //Set name of zFunction 
          for(Equation e in this.equations)  this.faseEquations.add(Equation.from(e));
          _transformZFunctionForFaseI(); //Transform ZFunction, setting 0 to X and 1 to A
          _sumArtificialRows(); //Sum all rows with artificial values and change faseIFunction

        do{
          newZFunction = new Equation();
          calculateIn(fases: true); //Calculate what variable will enter to 
          calculateOut(fases: true);
          generatePivotRow(fases: true);
          _calculateNewTable(fases: true);
          _passNewEquationsToOld(fases: true); //Set faseEquations to newEquations to continue
          _passNewzFunctionToOld(fases: true);
        }while(!this._optimalityCheck() && !inartificial && this.usedVariables.length < this.variables); //Cycle this pass until zFunction is optimized or no variables left
        if(this._optimalityCheck()){
          this.faseIOptimized = true;
          
        }else{
          this.faseIOptimized = false;
          this.solved = true;
          notifyListeners();
          return;
        }
        //FIXME: Also if an artificial stills in base it should break
        this.usedVariables.clear();
        // In this point faseEquation and faseFunction are equals as new function and equations
        // Now we need to copy fase to base and modify values to get the final table and check for its optimacy
        _transformZFunctionForFaseII();
      }
      if(this.faseIOptimized || !this.requireFases){

        do{
          newZFunction = Equation();
          calculateIn(); //Calculate variable that ins
          calculateOut(); //Calculate variable that outs
          generatePivotRow(); //Generate a row pivot converted
          _calculateNewTable(); //Calculate new table
          if(!this._optimalityCheck()) {
            _passNewEquationsToOld();
            _passNewzFunctionToOld();
            this.updatedFunction = new Equation.from(this.zFunction);
            updatedEquations.clear();
            for(Equation eq in this.equations) updatedEquations.add(Equation.from(eq));
            
          }else{
            this.optimized = true;
          }
          count++;
        }while(!this._optimalityCheck() && count < this.zFunction.values.length);
      }
      this.solved = true;
    }catch(error){
      print(error);
      throw MathException("Error processing info"); 
    }
    notifyListeners();
  }

  void _passNewzFunctionToOld({fases: false}){
    if(fases){
      this.faseIFunction = Equation.from(this.newZFunction);
    }else{
      this.zFunction = Equation.from(this.newZFunction);
    }
  }

  void _passNewEquationsToOld({fases:false}){
    if(fases){

      this.faseEquations.clear();
      for(Equation eq in this.newEquations) this.faseEquations.add(Equation.from(eq));
      // this.newEquations.clear();
    }else{
      this.equations.clear();
      for(Equation eq in this.newEquations) this.equations.add(Equation.from(eq));
    }
  }

  void _transformZFunctionForFaseI(){
    for(String key in this.faseIFunction.values.keys){
      if(key.contains("X")){

        this.faseIFunction.values.update(key, (value) => 0.0);
      }else if(key.contains("A")){
        this.faseIFunction.values.update(key, (value) => 1.0);
      }
    }
  }

  void _sumArtificialRows(){
    List<Equation> artificials = new List();

    for(Equation eq in this.faseEquations){
      if(eq.name.contains("A"))
        artificials.add(Equation.from(eq));
    }

    Map<String,double> vals = new Map();
    double res = 0.0;

    for(String key in this.faseIFunction.values.keys){
      vals[key] = 0.0;
      for(Equation eq in artificials){
        vals[key] += eq.values[key]??0.0;
      }
      vals[key]*=-1;
    }

    for(Equation eq in artificials){
      res += eq.res;
    }

    res*= -1;

    for(String key in this.faseIFunction.values.keys) this.faseIFunction.values[key] += vals[key];
    this.faseIFunction.res += res;

    artificials.clear();
  }

  void _setRowNames(){
    for(Equation eq in this.equations){
      eq.name = eq.getTableRowName();
    }
    zFunction.name = action ? "Z" : "G";
  }

  void _cleanEquations(){
    this.zFunction = new Equation();
    this.equations = new List<Equation>();
    this.newZFunction = new Equation();
    this.newEquations = new List<Equation>();
    this.faseIFunction = new Equation();
    this.faseEquations = new List<Equation>();
    this.firstFunction = new Equation();
    this.firstEquations = new List();
    this.updatedEquations = new List();
    this.updatedFunction = new Equation();
    this.pivotRow = new Equation(pivot: true);
    this.varIn = -1;
    this.varOut = -1;
    this.usedVariables.clear();
    this.solved = false;
    this.optimized = false;
    this.requireFases = false;
  }

  void _checkSigns(){
    for(Equation eq in this.equations){
      eq.convertSigns();
      eq.turnSigns();
    }
    this.zFunction.convertSigns();
  }

  void _transformZFunctionForFaseII(){
    for(String key in this.zFunction.values.keys.where((key) => !key.contains("X"))){
      this.zFunction.values[key] = this.faseIFunction.values[key];
    }

    this.zFunction.values.removeWhere((key, value) => key.contains("A"));
    this.equations.clear();
    this.newEquations.clear();
    for(Equation eq in this.faseEquations){
      this.equations.add(Equation.from(eq));
      this.equations.last.values.removeWhere((key, value) => key.contains("A"));
    }

    double res = 0.0;
    Map<String,double> sum = new Map();

    for(int i=0; i<this.equations.length; i++){
      double value = this.zFunction.values["X${i+1}"];
      if(value != null){

        for(String key in this.equations[i].values.keys){
          double inVal = this.equations[i].values[key];
          if(sum[key] != null){
            sum[key] += value * -1 * inVal;
          }else{
            sum[key] = value * -1 * inVal;
          }
        }
      }
      res += this.equations[i].res * -1 * value;
    }

    for(String key in this.zFunction.values.keys){
      this.zFunction.values[key] += sum[key];
    }

    this.zFunction.res += res;
  }

  void generatePivotRow({fases: false}){
    Map<String,double>  newVals = new Map(), oldVals;
    oldVals = fases ? this.faseEquations[varOut].values :  this.equations[varOut].values;
    double divideValue = fases ? this.faseEquations[varOut].values.values.elementAt(varIn) :  this.equations[varOut].values.values.elementAt(varIn);
    for(String key in oldVals.keys){
      double val = oldVals[key];
      val /= divideValue;
      newVals[key] = double.parse(val.toStringAsFixed(2));
    }

    this.pivotRow.setValuesMap(newVals);

    double res = fases ? this.faseEquations[varOut].res : this.equations[varOut].res;
    this.pivotRow.res = double.parse( (res / divideValue).toStringAsFixed(2) );

    this.pivotRow.name = this.pivotRow.getTableRowName(pivot: varIn);

  }

  void _addVariables() {
    int holgura, artificial;
    holgura = artificial  = 1;
    for(Equation eq in equations){
      if(eq.logical=='<='){
        eq.addH(holgura, 1);
        eq.setActions(this.equations.indexOf(eq), holgura);
        zFunction.addH(holgura++, 0);
      }else if(eq.logical == ">="){
        this.requireFases = true;
        notifyListeners();
        eq.addH(holgura, 1, holgura: false);
        eq.addA(artificial, 1);
        eq.setActions(this.equations.indexOf(eq) + 1, holgura, num2: artificial);
        zFunction.addH(holgura++, 0.0, holgura: false);
        zFunction.addA(artificial++, -1 );
      }else{
        this.requireFases = true;
        eq.addA(artificial, 1);
        eq.setActions(this.equations.indexOf(eq) + 1, artificial);
        zFunction.addA(artificial++, 1);
      }
    }
  }

  List<String> _getRowNamesAsList({fases: false}){
    List<String> rows = new List();
    if(fases){
      this.faseEquations.forEach((eq) {
        rows.add(eq.name);
      });
    }else{
      this.equations.forEach((eq) {
        rows.add(eq.name);
      });
    }

    return rows;
  }

  //If max I have to find the value that boost the Z to biggest positive
  //Else boost Z to the lowest negative
  void calculateIn({fases: false}) {
    double aux = 10000000000;
    
    for(int j=0; j<this.zFunction.values.length; j++){
      if(fases){
        if(aux >= faseIFunction.values.values.elementAt(j) 
          && !this._getRowNamesAsList(fases:fases).contains(this.zFunction.values.keys.elementAt(j))
          && !this.usedVariables.contains(faseIFunction.values.keys.elementAt(j))
        ){
          if(faseIFunction.values.values.elementAt(j) == 0) this.usedVariables.add(faseIFunction.values.keys.elementAt(j));
          else{
            aux = faseIFunction.values.values.elementAt(j);
            varIn = j;
          }
        }
      }else{
        
        if(aux >= zFunction.values.values.elementAt(j) 
          && !this._getRowNamesAsList(fases: fases).contains(this.zFunction.values.keys.elementAt(j))
          && !this.usedVariables.contains(zFunction.values.keys.elementAt(j))
        ){
          if(zFunction.values.values.elementAt(j) == 0) this.usedVariables.add(zFunction.values.keys.elementAt(j));
          else{
            aux = zFunction.values.values.elementAt(j);
            varIn = j;
          }
        }
      }
    }
    //Add variable to the used variables array to avoid using them again
    this.usedVariables.add(fases ? faseIFunction.values.keys.elementAt(varIn)  : zFunction.values.keys.elementAt(varIn));
    
  }

  void calculateOut({fases: false}) {
    double aux = 1000000000000.0;
    int out = 0;
    String varInKey = this.zFunction.values.keys.elementAt(varIn);
    for(Equation eq in fases ?  this.faseEquations : this.equations){
      if(aux >= ( eq.res / eq.values[varInKey]) && eq.values[varInKey] >= 0 
      ){
        if(fases){
          aux = (eq.res / eq.values[varInKey]);
          varOut = out;
        }else if(eq.res != 0.0){
          aux = (eq.res / eq.values[varInKey]);
          varOut = out;
        }
      }
      out++;
    }
  }

  String getOutName({fase : false}){
    if(fase) return this.faseEquations[varOut].name;
    else return this.equations[varOut].name;
  }

  String getInName(){
    return this.zFunction.values.keys.elementAt(varIn);
  }

  void _calculateNewTable({fases: false}){
    Map<String, double> values = new Map();
    this.newEquations.clear();
    double inVal = 0.0;
    if(fases)
      inVal = this.faseIFunction.values.values.elementAt(varIn) * -1;
    else
      inVal = this.zFunction.values.values.elementAt(varIn) * -1;
    
    for(String key in  fases ? this.faseIFunction.values.keys : this.zFunction.values.keys){
      double pivotValue = this.pivotRow.values[key];
      double val = fases ? this.faseIFunction.values[key]  :  this.zFunction.values[key];

      if(pivotValue == null) values[key] = double.parse(val.toStringAsFixed(2));
      else if(val == null) values[key] = double.parse((inVal * pivotValue).toStringAsFixed(2));
      else values[key] = double.parse(((inVal * pivotValue) + val).toStringAsFixed(2));
    }
    this.newZFunction = new Equation();
    this.newZFunction.setValuesMap(values);
    double res = (fases ? this.faseIFunction.res :  this.zFunction.res);
    this.newZFunction.res = double.parse(((inVal * this.pivotRow.res) + res).toStringAsFixed(2)); 
    this.newZFunction.name = fases ? this.faseIFunction.name  : this.zFunction.name;

    for(int i=0; i<(fases ? this.faseEquations.length : this.equations.length); i++){
      if(i == varOut){
        this.newEquations.add(Equation.from(this.pivotRow));
      }else{
        Equation eq = new Equation();
        values = new Map();
        inVal = fases ? this.faseEquations[i].values.values.elementAt(varIn) * -1 : this.equations[i].values.values.elementAt(varIn) * -1;
        inVal = double.parse(inVal.toStringAsFixed(2));
        for(String key in this.zFunction.values.keys){
          double pivotValue = this.pivotRow.values[key];
          double value = fases ? this.faseEquations[i].values[key] : this.equations[i].values[key];
          if(pivotValue == null){
            if(value == null) values[key] = 0.0;
            else values[key] = double.parse(value.toStringAsFixed(2));
          }else if(value == null){
            values[key] =  double.parse((inVal * pivotValue).toStringAsFixed(2));
          }else{
            values[key] = double.parse(((inVal * pivotValue ) + value).toStringAsFixed(2));
          }
        }
        eq.setValuesMap(values);
        double res = (fases ? this.faseEquations[i].res : this.equations[i].res);
        eq.res = double.parse(((inVal * this.pivotRow.res) +  res).toStringAsFixed(2));
        eq.name = fases ? this.faseEquations[i].name :  this.equations[i].name;
        this.newEquations.add(eq);
      }
    }
  }

  bool _optimalityCheck(){

      for(double value in this.newZFunction.values.values)  if(value < 0) return false;

      for(Equation eq in this.newEquations){
        if(eq.name.contains("A")) {
          inartificial = true;
          return false;
        }
      }
    
    return true;
  }

  List<TableRow> optimizedValues(){
    List<TableRow> rows = new List();
    TableRow row = new TableRow(
      children: [
        TableCell(child: Center(child: Text("${action ? "Z": "G"} = ${newZFunction.res}", style:TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue))),),
        
      ]
    );
    rows.add(row);
    if(!action){
      rows.add(TableRow(
        children: [
          TableCell(child: Center(child: Text("Z = ${newZFunction.res * -1}", style:TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue))),),
        ]
      ));
    }
    Map<String,double> results = new Map();
    for(String key in this.newZFunction.values.keys){
      this.newEquations.forEach((eq) {
        if(eq.name == key){
          results[key] = eq.res;
        }else{
          if(!(results[key] != null && results[key] != 0.0)){

            results[key] = 0.0;
          }
        }
      });
    }

    for(String key in results.keys){
      row = new TableRow(
        children: [
          TableCell(child: Text("$key = ${results[key]}", textAlign: TextAlign.center, style:TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),),)
        ]
      );
      rows.add(row);
    }
    return rows;
  }

  void clean() {
    this._cleanEquations();
    notifyListeners();
  } 
}