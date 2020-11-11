import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simplex/providers/SimplexProvider.dart';

class SolutionPage extends StatefulWidget {
  @override
  _SolutionPageState createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  int _currPage = 0;
  PageController _pageController = new PageController();

  @override
  void initState() { 
    super.initState();
    
  }

  List<Widget> _buildPageIndicator(){
    List<Widget> list = [];
    for(int i=0; i<3; i++){
      list.add(i==_currPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool active){
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: active ? 16.0 : 8.0,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(12))
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Consumer<Simplex>(
      builder: (context,simplex, _) {
        return simplex.solved ?  Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: h*0.8,
                child: PageView(
                  physics: ClampingScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (int page){
                    this.setState(() {
                      this._currPage = page;
                    });
                  },
                  children: [
                    _first(simplex),
                    simplex.requireFases ? 
                    _faseII(simplex) : _cociente(simplex),
                    simplex.requireFases ? _cociente(simplex) : Container(),
                  ],
                ),
              ),
              Container(
                  height: h * 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                )
            ],
          ),
        ) : Container();
      }
    );
  }

  Widget _first(Simplex simplex){
    double h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pasamos el problema a la forma estandar, añandiendo las variables necesarias.", style:TextStyle(fontSize: 18,)),
          Container(
            height: h*0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey, width: 0.4),
            ),
            child: ListView.builder(
              itemCount: simplex.firstEquations.length,
              itemBuilder: (ctx, i) {
                return ListTile(
                  leading: Icon(Icons.border_all_rounded, size: 18, color: Colors.black),
                  title: Text(simplex.firstEquations[i].variableAction),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(simplex.action ? "MAXIMIZAR" : "MINIMIZAR", style:TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(simplex.firstFunction.toString(z: true, action: simplex.action), style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  
                ]..addAll(simplex.firstEquations.map<Widget>(((eq) => Text(eq.toString(), style:TextStyle(fontSize: 18))))),
              )
            ),
          ),
          
          SizedBox(height: 24,),
          Text("Siendo representada en la siguiente tabla: "),
          SizedBox(height: 24,),
          Center(
            child: Table(
              border: TableBorder.all(color: Colors.black,width: 1),
              children: [
                _tableHeader(simplex, initial:true),
                simplex.firstFunction.toRow(simplex.firstFunction.header(), z:true)
              ]..addAll(simplex.firstEquations.map<TableRow>((e) {
                return e.toRow(simplex.firstFunction.header());
              })),
            )
          ),
          
          simplex.requireFases 
            ? Column(
              children: [
                SizedBox(height: 32),
                Center(child: Text("Fase I", style:TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.red))),
                Table(
                  border: TableBorder.all(color: Colors.black, width: 1),
                  children: [
                    _tableHeader(simplex, fase:true),
                    simplex.faseIFunction.toRow(simplex.faseIFunction.header(), z:true),
                  ]..addAll(simplex.faseEquations.map<TableRow>((e) => e.toRow(simplex.faseIFunction.header()))),
                ),
                SizedBox(height: 16),
                simplex.faseIOptimized
                  ?
                  Text("Ya que todas las variables artificiales desaparecieron de la base, y la tabla es óptima, se procede a la fase II", style:TextStyle(fontWeight: FontWeight.w700))
                  : Text("El sistema no tiene solución porque la función objetivo ya es óptima pero no han desaparecido las variables artificiales", style:TextStyle(fontWeight: FontWeight.w700)),
              ],
            )
            : Text("Seleccionando como criterio de entrada a ${simplex.getInName()}", style:TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  TableRow _tableHeader(Simplex simplex, {fase= false, initial: false}){

    List<String> header = fase ? simplex.faseIFunction.header() : initial ? simplex.firstFunction.header() :   simplex.zFunction.header();
    
    List<TableCell> cells = new List();
    cells.add(TableCell(child: Container()));
    cells.add(TableCell(child: Center(child: Text(simplex.action ? "Z" : "G", style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)))));
    header.forEach((h) {
      cells.add(TableCell(child: Center(child: Text(h, style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))),));
    });
    cells.add(TableCell(child: Container()));
    return TableRow(children: cells);

  }

  Widget _faseII(Simplex simplex){
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text("Fase II", style:TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.red)),),
          Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            children: [
              _tableHeader(simplex),
              simplex.zFunction.toRow(simplex.zFunction.header(), z:true),
            ]..addAll(simplex.equations.map<TableRow>((e) => e.toRow(simplex.zFunction.header()))),
          ),
          Text("Seleccionando como criterio de entrada a ${simplex.getInName()}", style:TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _cociente(Simplex simplex){
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Obtenemos la columna pivote (Criterio de entrada) y el Criterio de Salida: "),
          SizedBox(height: 16),
          Center(
            child: Table(
              border: TableBorder.all(color: Colors.black, width: 1),
              children: [
                simplex.zFunction.getOutHeader(simplex.varIn),
                simplex.zFunction.getOutRow(simplex.varIn, z: true)
              ]..addAll(simplex.equations.map<TableRow>((element) => element.getOutRow(simplex.varIn,))),
            ),
          ),
          Text("Seleccionando la variable de salida a ${simplex.getOutName()}", style:TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16,),
          Text("El renglón pivote queda así: ",style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Table(
            border: TableBorder.all(color: Colors.black, width:1),
            children: [simplex.pivotRow.toRow(simplex.zFunction.header(), pivot: simplex.varIn)],
          ),
          Divider(),
          SizedBox(height: 16,),
          Text("Dando una nueva tabla transformada: " ,style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8,),
          Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            children: [
              _tableHeader(simplex),
              simplex.newZFunction.toRow(simplex.zFunction.header(), z: true),
            ]..addAll(simplex.newEquations.map<TableRow>((eq) => eq.toRow(simplex.zFunction.header(), pivot: eq.pivot ? simplex.varIn :  -1))),
          ),
          SizedBox(height: 24,),
          Text("La prueba de optimalidad se aplica y se llega a la conclusión que el resultado ${simplex.optimized ? "es óptimo" : "no es óptimo"}", style:TextStyle(fontSize: 24, color: Colors.red)),
          simplex.optimized ?  Center(
            child: Column(
              children: [
                Center(child: Text("Valores optimos: ", style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Center(
                  child: Table(
                    border: TableBorder.all(color: Colors.black, width: 1),
                    children: simplex.optimizedValues()
                  ),
                )
              ],
            ),
          ) : Container()
        ]
      )
    );
  }
    
}