import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simplex/models/equation.dart';
import 'package:simplex/providers/SimplexProvider.dart';
import 'package:simplex/screens/solution.dart';
import 'package:toggle_switch/toggle_switch.dart';


class EntriesPage extends StatefulWidget {
  @override
  _EntriesPageState createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  int _variableCount = 2, _restrictionCount = 2;
  GlobalKey<FormState> _formKey = new GlobalKey();
  int action = 0;
  List<Equation> equations = new List();
  Equation zFunction ;
  String cleaner = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init(){
    this.zFunction = new Equation(variables: _variableCount);
    for(int i=0; i<this._restrictionCount; i++){
      Equation rest = new Equation(variables: this._variableCount);
      this.equations.add(rest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _adjustButtons("Número de variables: "),
            _adjustButtons("Número de restricciones: ", variable: false),
            SizedBox(height: 16),
            Center(
              child: ToggleSwitch(
                initialLabelIndex: this.action,
                labels: ["Maximizar", "Minimizar"],
                minWidth: 150,
                activeBgColor: Colors.red,
                inactiveBgColor: Colors.white,
                fontSize: 18,
                onToggle: (val){
                  this.setState(() {
                    this.action = val;

                  });
                },
              ),
            ),
            SizedBox(height: 16),
            Text("Ingresa la función objetivo: ", style:TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Form(
              key: this._formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   this._zFunctionInput(),
                    Center(
                      child: this._restrictions(),
                    ),
                ],
              ),
            ),
            // this._zFunctionInput(),
            // Center(
            //   child: this._restrictions(),
            // ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                RaisedButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.red,
                  onPressed: (){
                    try{

                      Provider.of<Simplex>(context,listen:false).processInfo(zFunction, equations, action == 0, this._variableCount);
                    }catch(error){
                      print(error);
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text("¡Error!",textAlign: TextAlign.center, style:TextStyle(fontSize: 28,fontWeight: FontWeight.w600, color: Colors.red)),
                          content: Text("Error al procesar la información, revise que todos sus campos sean correctos", textAlign: TextAlign.center, style:TextStyle(fontSize: 18)),
                          actions: [
                            FlatButton(
                              onPressed: (){
                                Navigator.pop(this.context);
                              },
                              child: Text("Okay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                              
                            )
                          ],
                        )
                      );
                    }
                  },
                  child: Container(
                    width: 155,
                    height: 75,
                    child: Center(
                      child: Text("Resolver", style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)),
                    ),
                  ),
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  onPressed: (){
                    this.setState(() {
                      this._variableCount = 2;
                      this._restrictionCount = 2;
                      action = 0;
                      init();
                      this._formKey.currentState.reset();
                    });

                    Provider.of<Simplex>(context,listen:false).clean();
                    
                  },
                  child: Container(
                    width: 155,
                    height: 75,
                    child: Center(
                      child: Text("Limpiar", style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.red)),
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            SolutionPage(),
          ],
        ),
      ),
    );
  }

  Widget _zFunctionInput(){
    double w = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(left: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Z= ", style:TextStyle(fontSize: 18)),
          Container(
            height: 75,
            width: w*0.85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: this._variableCount,
              itemBuilder: (ctx, i){
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 35,
                      child: TextFormField(
                        initialValue: cleaner,
                        keyboardType: TextInputType.number,
                        onChanged: (val){
                          this.setState(() {
                            
                            zFunction.values["X${i+1}"] = double.parse(val);
                          });
                        } ,
                      ),
                    ),
                    Text("X${i+1}", style:TextStyle(fontSize: 18)),
                    i<this._variableCount-1 ? DropdownButton(
                      value: this.zFunction.signs[i],
                      items: [
                        DropdownMenuItem(child: Text("+", style:TextStyle(fontSize: 18)), value: "+"),
                        DropdownMenuItem(child: Text("-", style:TextStyle(fontSize: 18)), value: "-"),
                      ],
                      onChanged: (val){
                        this.setState(() {
                          this.zFunction.signs[i] = val;
                        });
                      },
                    ) : Container()
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
  
  Widget _restrictions(){
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.6)
      ),
      height: h*0.4,
      child: ListView.builder(
        itemCount: this._restrictionCount,
        itemBuilder: (ctx,i) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text("${i+1}. ", style:TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                width: w*0.7,
                height: 75,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: this._variableCount + 1,
                  itemBuilder: (ctx, j){
                    if(j==this._variableCount){
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            child: DropdownButton(
                              value: this.equations[i].logical,
                              items: [
                                DropdownMenuItem(child: Text(">=", style:TextStyle(fontSize: 14)), value: ">=",),
                                DropdownMenuItem(child: Text("<=", style:TextStyle(fontSize: 14)), value: "<=",),
                                DropdownMenuItem(child: Text("=", style:TextStyle(fontSize: 14)), value: "=",),
                              ],
                              onChanged: (val){
                                this.setState(() {
                                  this.equations[i].logical = val;
                                });
                              },
                            ),
                          ),
                          Container(
                            width: 35,
                            child: TextFormField(
                              initialValue: cleaner,
                              keyboardType: TextInputType.number,
                              onChanged: (val){
                                this.equations[i].res = double.parse(val);
                              } ,
                            ),
                          ),
                        ],
                      );
                    }else{
                      return this._restrictionItem(i,j);
                    }
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }


  Widget _restrictionItem(int i, int j){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 35,
          child: TextFormField(
            initialValue: cleaner,
            keyboardType: TextInputType.number,
            onChanged: (val){
              this.setState(() {
                
                this.equations[i].values["X${j+1}"] = double.parse(val);
              });
            } ,
          ),
        ),
        Text("X${j+1}", style:TextStyle(fontSize: 18)),
        j<this._variableCount-1 
          ? Container(
            margin: EdgeInsets.all(4),
            child: DropdownButton(
              value: this.equations[i].signs[j],
              items: [
                DropdownMenuItem(child: Text("+", style:TextStyle(fontSize: 18)), value: "+"),
                DropdownMenuItem(child: Text("-", style:TextStyle(fontSize: 18)), value: "-"),
              ],
              onChanged: (val){
                this.setState(() {
                  
                  this.equations[i].signs[j] = val;
                });
              },
            ),
        ) : Container()
      ],
    );
  }

  Widget _adjustButtons(String message, {variable = true}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(message, style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Container(
          width: 35,
          child: RaisedButton(
            color: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))),
            child: Center(child: Text("+", style:TextStyle(fontSize: 18))),
            onPressed: (){
              if(variable){
                if(this._variableCount < 10){
                  this.setState(() {
                    this._variableCount++;
                    this.zFunction.addSign("+");
                    for(final e in this.equations) e.addSign("+");
                  });
                }
              }else{
                if(this._restrictionCount < 10){
                  this.setState(() {
                    this._restrictionCount++;
                  });
                  this.equations.add(new Equation(variables: this._variableCount));
                }
              }
            },
          ),
        ),
        Container(
          width: 35,
          child: Container(child: Text("${variable?this._variableCount.toString() : this._restrictionCount.toString()}", style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center,))
        ),
        Container(
          width: 35,
          child: RaisedButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
            child: Center(child: Text("-", style:TextStyle(fontSize: 18))),
            onPressed: (){
              if(variable){
                if(this._variableCount > 2){
                  this.setState(() {
                    this._variableCount --;
                    this.zFunction.removeSign();
                    for(final e in this.equations) e.removeSign();
                  });
                }
              }else{
                if(this._restrictionCount > 2){
                  this.setState(() {
                    this._restrictionCount--;
                    this.equations.removeLast();
                  });
                }
              }
            },
          ),
        ),
      ],
    );
  }

  
}