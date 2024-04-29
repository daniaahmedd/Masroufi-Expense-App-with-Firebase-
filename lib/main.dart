import 'package:flutter/material.dart';
import 'ExlistWidget.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'NewExWidget.dart';
import 'expense.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masroufi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: mainPage(),   //mainPageHook(),
    );
  }
}

class mainPage extends StatefulWidget {
  const mainPage({super.key});

  @override
  State<mainPage> createState() => _mainPageState();
}

class _mainPageState extends State<mainPage> {
  final List<expense> allExpenses = [];
  final expenseURL = Uri.parse('https://masroufidb-default-rtdb.firebaseio.com/expensesTable.json');

  @override
  void initState() {
  fetchExpensesFromServer();
  super.initState();
}

 Future<void> fetchExpensesFromServer() async {
    try {
      var response = await http.get(expenseURL);
      if(json.decode(response.body) == null){
        return;
      }
      var fetchedData = json.decode(response.body) as Map<String, dynamic>;
      print(fetchedData);
      setState(() {
        allExpenses.clear();
        fetchedData.forEach((key, value) {
        print(value['expenseDate']);
        allExpenses.add(expense(
          id: key,
          title: value['expenseTitle'],
          amount: value['expenseAmount'],
          date: DateTime.parse(value['expenseDate'])
          ));
        });
      });
    } catch (err) {
      print(err);
    }
  }
  Future<void> addExpensetoDB(String t,double a, DateTime d) {
    return http
    .post(expenseURL, body: json.encode({'expenseTitle':t, 'expenseAmount': a, 'expenseDate': d.toIso8601String()}))
    .then((response) {
    }).catchError((err) {
    print("provider:" + err.toString());
    throw err;
    });
  }
  Future<void> deleteEx(String id_to_delete) async {
    print(id_to_delete);
    var ideaToDeleteURL = Uri.parse(
    'https://masroufidb-default-rtdb.firebaseio.com/expensesTable/$id_to_delete.json');
    try {
     var response=await http.delete(ideaToDeleteURL); // wait for the delete request to be done
     print('hi from response');
     print(response.body);
    } catch (err) {
    print(err);
    }

    }

  void addnewExpense(
      {required String t, required double a, required DateTime d}) {
    setState(() {
      addExpensetoDB(t, a, d).then((value) => allExpenses.add(
          expense(amount: a, date: d, id: DateTime.now().toString(), title: t)))
      ;
    });
    fetchExpensesFromServer();
    Navigator.of(context).pop();
  }

  void deleteExpense({required String id}) {
      print('id');
      print(id);
      deleteEx(id).then((value) {
        print('hereeeee');
         setState(() {
        allExpenses.removeWhere((element) {
        // when done, remove it locally.
        return element.id == id;
        }) ;   });
      
      print('allExpenses =>>>> $allExpenses');
    });
  }

  double calculateTotal() {
    double total = 0;
    allExpenses.forEach((e) {
      total += e.amount;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (b) {
                return ExpenseForm(addnew: addnewExpense);
              });
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (b) {
                      return ExpenseForm(addnew: addnewExpense);
                    });
              },
              icon: Icon(Icons.add))
        ],
        title: Text('Masroufi'),
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(10),
            height: 100,
            child: Card(
              elevation: 5,
              child: Center(
                  child: Text(
                'EGP ' + calculateTotal().toString(),
                style: TextStyle(fontSize: 30),
              )),
            ),
          ),
          EXListWidget(allExpenses: allExpenses, deleteExpense: deleteExpense),
        ],
      ),
    );
  }
}
