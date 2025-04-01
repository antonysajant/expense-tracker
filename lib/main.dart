import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final name = reader.readString();
    final amount = reader.readDouble();
    final dateMillis = reader.readInt();
    final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);
    return Expense(name: name, amount: amount, date: date);
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.amount);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class Expense {
  final String name;
  final double amount;
  final DateTime date;

  Expense({required this.name, required this.amount, required this.date});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');
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
          bodyLarge: TextStyle(fontFamily: 'Jost'),
          bodyMedium: TextStyle(fontFamily: 'Jost'),
          bodySmall: TextStyle(fontFamily: 'Jost'),
          displayLarge: TextStyle(fontFamily: 'Jost'),
          displayMedium: TextStyle(fontFamily: 'Jost'),
          displaySmall: TextStyle(fontFamily: 'Jost'),
          headlineLarge: TextStyle(fontFamily: 'Jost'),
          headlineMedium: TextStyle(fontFamily: 'Jost'),
          headlineSmall: TextStyle(fontFamily: 'Jost'),
          labelLarge: TextStyle(fontFamily: 'Jost'),
          labelMedium: TextStyle(fontFamily: 'Jost'),
          labelSmall: TextStyle(fontFamily: 'Jost'),
          titleLarge: TextStyle(fontFamily: 'Jost'),
          titleMedium: TextStyle(fontFamily: 'Jost'),
          titleSmall: TextStyle(fontFamily: 'Jost'),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.tealAccent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
  DateTime _selectedDate = DateTime.now();
  String? _errorText;

  Box<Expense> expensesBox = Hive.box<Expense>('expenses');

  Map<String, List<Expense>> get _groupedExpenses {
    final Map<String, List<Expense>> grouped = {};
    final expenses = expensesBox.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));

    for (var expense in expenses) {
      final dateKey = DateFormat.yMMMd().format(expense.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }
    return grouped;
  }

  Map<String, double> get _dailyExpensesData {
    final dailyTotals = <String, double>{};
    final expenses = expensesBox.values.toList();

    for (var expense in expenses) {
      final dateKey = DateFormat.MMMd().format(expense.date);
      dailyTotals.update(dateKey, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final sortedDailyTotals = Map.fromEntries(dailyTotals.entries.toList()
      ..sort((e1, e2) => DateFormat.MMMd()
          .parse(e1.key)
          .compareTo(DateFormat.MMMd().parse(e2.key))));

    return sortedDailyTotals;
  }

  int expenseLimit = 500; // Initialize the expense limit

  Widget _buildBarChart() {
    final dailyData = _dailyExpensesData;
    if (dailyData.isEmpty) {
      return const Center(
        child: Text(
          "Add expenses to see the chart",
          style: TextStyle(color: Colors.white70, fontFamily: 'Jost'),
        ),
      );
    }

    final dates = dailyData.keys.toList();
    final amounts = dailyData.values.toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxAmount * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.grey[800]!,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${dates[groupIndex]}\n\$${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Jost',
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < dates.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dates[index],
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 10,
                            fontFamily: 'Jost',
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Remove Y-axis titles
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: false, // Remove horizontal lines
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: false, // Remove the border
            ),
            barGroups: List.generate(amounts.length, (index) {
              final isOverLimit = amounts[index] > expenseLimit;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: amounts[index],
                    color: isOverLimit ? Colors.red : Colors.tealAccent,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
                showingTooltipIndicators: [0],
              );
            }),
          ),
        ),
      ),
    );
  }

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
              title: const Text(
                "Add Expense",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Jost'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Expense Name",
                        labelStyle: TextStyle(
                            color: Colors.white70, fontFamily: 'Jost'),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.tealAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Jost'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: const TextStyle(
                            color: Colors.white70, fontFamily: 'Jost'),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.tealAccent),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                        errorText: _errorText,
                      ),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Jost'),
                      onChanged: (value) {
                        setState(() {
                          _errorText =
                              (value.isEmpty || double.tryParse(value) == null)
                                  ? "Please enter a valid number"
                                  : null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                            style: const TextStyle(
                                color: Colors.white70, fontFamily: 'Jost'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.tealAccent),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    textTheme: const TextTheme(
                                      bodyLarge: TextStyle(fontFamily: 'Jost'),
                                      bodyMedium: TextStyle(fontFamily: 'Jost'),
                                      bodySmall: TextStyle(fontFamily: 'Jost'),
                                      displayLarge:
                                          TextStyle(fontFamily: 'Jost'),
                                      displayMedium:
                                          TextStyle(fontFamily: 'Jost'),
                                      displaySmall:
                                          TextStyle(fontFamily: 'Jost'),
                                      headlineLarge:
                                          TextStyle(fontFamily: 'Jost'),
                                      headlineMedium:
                                          TextStyle(fontFamily: 'Jost'),
                                      headlineSmall:
                                          TextStyle(fontFamily: 'Jost'),
                                      labelLarge: TextStyle(fontFamily: 'Jost'),
                                      labelMedium:
                                          TextStyle(fontFamily: 'Jost'),
                                      labelSmall: TextStyle(fontFamily: 'Jost'),
                                      titleLarge: TextStyle(fontFamily: 'Jost'),
                                      titleMedium:
                                          TextStyle(fontFamily: 'Jost'),
                                      titleSmall: TextStyle(fontFamily: 'Jost'),
                                    ),
                                    colorScheme: ColorScheme.dark(
                                      primary: Colors.teal,
                                      onPrimary: Colors.black,
                                      surface: Colors.grey[900]!,
                                      onSurface: Colors.white,
                                    ),
                                    dialogTheme: const DialogThemeData(
                                      backgroundColor: Colors.black,
                                      titleTextStyle:
                                          TextStyle(fontFamily: 'Jost'),
                                      contentTextStyle:
                                          TextStyle(fontFamily: 'Jost'),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() => _selectedDate = pickedDate);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel",
                      style: TextStyle(
                          color: Colors.redAccent, fontFamily: 'Jost')),
                ),
                TextButton(
                  onPressed: () {
                    if (_amountController.text.isEmpty ||
                        double.tryParse(_amountController.text) == null) {
                      setState(
                          () => _errorText = "Please enter a valid number");
                      return;
                    }

                    final newExpense = Expense(
                      name: _nameController.text,
                      amount: double.parse(_amountController.text),
                      date: _selectedDate,
                    );

                    Navigator.of(context).pop();
                    _addExpense(newExpense);
                  },
                  child: const Text("Add",
                      style: TextStyle(
                          color: Colors.tealAccent, fontFamily: 'Jost')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      expensesBox.add(expense);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedExpenses = _groupedExpenses;
    final dateKeys = groupedExpenses.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MoneyMate",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Jost',
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900], // Darker drawer color
        child: Center(
          // Center the entire Column vertically and horizontally
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            mainAxisSize:
                MainAxisSize.min, // Make the Column take minimum space
            children: [
              const Text(
                'MoneyMate',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 24,
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20), // Add spacing
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.tealAccent),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.white, fontFamily: 'Jost')),
                onTap: () {
                  // Navigate to settings page
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: expensesBox.isEmpty
          ? const Center(
              child: Text(
                "No expenses added yet",
                style: TextStyle(
                    color: Colors.white70, fontSize: 16, fontFamily: 'Jost'),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Daily Expenses",
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBarChart(),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemCount: dateKeys.length,
                    itemBuilder: (context, dateIndex) {
                      final date = dateKeys[dateIndex];
                      final expensesForDate = groupedExpenses[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              date,
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Jost',
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expensesForDate.length,
                            itemBuilder: (context, expenseIndex) {
                              final expense = expensesForDate[expenseIndex];
                              return Dismissible(
                                key: Key(
                                    '${expense.name}_${expense.date.millisecondsSinceEpoch}'),
                                background: Container(color: Colors.red),
                                onDismissed: (direction) {
                                  setState(() {
                                    final index = expensesBox.values
                                        .toList()
                                        .indexOf(expense);
                                    if (index != -1) {
                                      expensesBox.deleteAt(index);
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('${expense.name} removed',
                                            style: const TextStyle(
                                                fontFamily: 'Jost'))),
                                  );
                                },
                                child: Card(
                                  color: Colors.grey[900],
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: ListTile(
                                    title: Text(expense.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Jost')),
                                    subtitle: Text(
                                      DateFormat.jm().format(expense.date),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'Jost'),
                                    ),
                                    trailing: Text(
                                      "\$${expense.amount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'Jost',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Jost'),
        ),
      ),
      body: const Center(
        child: Text('Settings Page Content',
            style: TextStyle(color: Colors.white, fontFamily: 'Jost')),
      ),
    );
  }
}
