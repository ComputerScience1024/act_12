import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Required to initialize Firebase
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key, required this.title});
  final String title;

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference inventory =
      FirebaseFirestore.instance.collection('items');

  Future<void> _addInventoryItem() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Inventory Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                int quantity = int.tryParse(quantityController.text.trim()) ?? 0;

                if (name.isNotEmpty) {
                  await inventory.add({
                    'name': name,
                    'quantity': quantity,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateInventoryItem(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    TextEditingController nameController = TextEditingController(text: data['name']);
    TextEditingController quantityController =
        TextEditingController(text: data['quantity'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Inventory Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                int quantity = int.tryParse(quantityController.text.trim()) ?? 0;

                if (name.isNotEmpty) {
                  await inventory.doc(doc.id).update({
                    'name': name,
                    'quantity': quantity,
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteInventoryItem(String id) async {
    await inventory.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: inventory.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading items'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No inventory items found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              final quantity = data['quantity'] ?? 0;

              return ListTile(
                title: Text(name),
                subtitle: Text('Quantity: $quantity'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateInventoryItem(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteInventoryItem(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addInventoryItem,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
