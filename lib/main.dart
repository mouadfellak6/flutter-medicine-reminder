import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() {
  runApp(const MyApp());
}

class Medicine {
  String name;
  String dose;
  TimeOfDay time;
  String type;

  Medicine({
    required this.name,
    required this.dose,
    required this.time,
    required this.type,
  });
}

class MedicineNotifier extends ChangeNotifier {
  List<Medicine> medicines = [];

  void addMedicine(Medicine medicine) {
    medicines.add(medicine);
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicineNotifier(),
      child: MaterialApp(
        title: 'Medicine Reminder',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal),
          fontFamily: 'Roboto',
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.teal,
      ),
      body: const MedicineList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicinePage()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MedicineList extends StatelessWidget {
  const MedicineList({Key? key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineNotifier>(
      builder: (context, medicineNotifier, child) {
        return ListView.builder(
          itemCount: medicineNotifier.medicines.length,
          itemBuilder: (context, index) {
            Medicine medicine = medicineNotifier.medicines[index];
            return Card(
              elevation: 3,
              margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(
                  medicine.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dose: ${medicine.dose}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Time: ${medicine.time.format(context)}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                leading: Image.asset(
                  'assets/${medicine.type.toLowerCase()}.png',
                  width: 50,
                  height: 50,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AddMedicinePage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  TimeOfDay? selectedTime;
  String selectedType = 'Syrup';

  AddMedicinePage({Key? key});

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      selectedTime = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    tz.initializeTimeZones();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: doseController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Dose',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedType,
              hint: const Text('Select Medicine Type',
                  style: TextStyle(color: Colors.white)),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedType = newValue;
                }
              },
              items: <String>['Syrup', 'Syringe', 'Pills']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/${value.toLowerCase()}.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reminder Time: ${selectedTime?.format(context) ?? ""}'),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                  child: const Text('Select Time',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                MedicineNotifier medicineNotifier =
                    context.read<MedicineNotifier>();
                if (selectedTime != null) {
                  Medicine medicine = Medicine(
                    name: nameController.text,
                    dose: doseController.text,
                    time: selectedTime!,
                    type: selectedType,
                  );
                  medicineNotifier.addMedicine(medicine);
                  scheduleNotification(medicine);
                  Navigator.pop(context);
                } else {
                  // Handle case where no time is selected
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('app_icon');
    IOSInitializationSettings iosInitializationSettings =
        const IOSInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      medicine.time.hour,
      medicine.time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    int notificationId = medicine.hashCode;

    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'Medicine Reminder',
      'Reminds you to take your medicine',
      priority: Priority.high,
      importance: Importance.high,
      ticker: 'ticker',
      styleInformation: DefaultStyleInformation(true, true),
    );

    IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Medicine Reminder',
      'It\'s time to take your ${medicine.name} dose!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }
}
