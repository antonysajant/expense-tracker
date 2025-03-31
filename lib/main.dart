import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Boldonse'),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(
          brightness: Brightness.dark,
          secondary: Colors.tealAccent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;
  String? _errorText;

  void _showAddExpenseDialog() {
    _nameController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _errorText = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text("Add Expense",
                  style: TextStyle(
                      fontFamily: 'Boldonse',
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Expense Name",
                      labelStyle: TextStyle(
                          fontFamily: 'Boldonse', color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.tealAccent)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                    ),
                    style: const TextStyle(
                        fontFamily: 'Boldonse', color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      labelStyle: const TextStyle(
                          fontFamily: 'Boldonse', color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.tealAccent)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal)),
                      errorText: _errorText,
                    ),
                    style: const TextStyle(
                        fontFamily: 'Boldonse', color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty || double.tryParse(value) == null) {
                          _errorText = "Please enter a valid number";
                        } else {
                          _errorText = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Date: ${DateFormat.yMMMd().format(_selectedDate!)}",
                          style: const TextStyle(
                              fontFamily: 'Boldonse', color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.tealAccent),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: Colors.teal,
                                    onPrimary: Colors.black,
                                    surface: Colors.grey[900] ?? Colors.black,
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: Colors.black,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel",
                      style: TextStyle(
                          fontFamily: 'Boldonse', color: Colors.redAccent)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_amountController.text.isEmpty ||
                          double.tryParse(_amountController.text) == null) {
                        _errorText = "Please enter a valid number";
                        return;
                      }
                      _errorText = null;
                    });
                    if (_errorText == null) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Add",
                      style: TextStyle(
                          fontFamily: 'Boldonse', color: Colors.tealAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Expense Tracker",
              style: TextStyle(
                  fontFamily: 'Boldonse', fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          const Center(
            child: Text("No expenses added yet",
                style: TextStyle(
                    fontFamily: 'Boldonse',
                    color: Colors.white70,
                    fontSize: 16)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
