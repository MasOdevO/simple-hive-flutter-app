import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('medicine');
  await Hive.openBox('medicine');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'قاعدة بيانات الدواء',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      locale: const Locale('ar'),
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];

  final _medicine = Hive.box('medicine');

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

//*****************************
//CRUD operations :-
//****************************

// 1) create operation
  // Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _medicine.add(newItem);
    _refreshItems(); // update the UI
  }

// 2) read operation
  // Get all items from the database
  void _refreshItems() {
    final data = _medicine.keys.map((key) {
      final value = _medicine.get(key);
      return {"key": key, "name": value["name"], "category": value['category']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // Retrieve a single item from the database by using its key
  // Map<String, dynamic> _readItem(int key) {
  //   final item = _medicine.get(key);
  //   return item;
  // }

// 3) update operation
  // Update a single item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _medicine.put(itemKey, item);
    _refreshItems(); // Update the UI
  }

// 4) delete operation
  // Delete a single item
  Future<void> _deleteItem(int itemKey) async {
    await _medicine.delete(itemKey);
    _refreshItems(); // update the UI

    // Display a snackbar
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم حذف الدواء بنجاح')));
  }

  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item

    if (itemKey != null) {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _categoryController.text = existingItem['category'];
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'الاسم'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(hintText: 'الصنف'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (itemKey == null) {
                        _createItem({
                          "name": _nameController.text,
                          "category": _categoryController.text
                        });
                      }

                      // update an existing item
                      if (itemKey != null) {
                        _updateItem(itemKey, {
                          'name': _nameController.text.trim(),
                          'category': _categoryController.text.trim()
                        });
                      }

                      // Clear the text fields
                      _nameController.text = '';
                      _categoryController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(itemKey == null ? 'إضافة' : 'تعديل'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قاعدة بيانات الدواء'),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد بيانات',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final currentItem = _items[index];
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                      title: Text(currentItem['name']),
                      subtitle: Text(currentItem['category'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showForm(context, currentItem['key'])),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(currentItem['key']),
                          ),
                        ],
                      )),
                );
              }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
