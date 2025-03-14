import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'dart:async';

void main() {
  runApp(ReservationApp());
}

class ReservationApp extends StatelessWidget {
 const  ReservationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Réservation de Salle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReservationScreen(),
    );
  }
}

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final Semaphore _semaphore = Semaphore(1); // Une seule ressource disponible
  String _roomStatus = 'Libre';
  String _person1Status = 'En attente';
  String _person2Status = 'En attente';

  Future<void> _reserveRoom(int personId, int durationInSeconds) async {
    setState(() {
      if (personId == 1) {
        _person1Status = 'Tente de réserver...';
      } else {
        _person2Status = 'Tente de réserver...';
      }
    });

    await _semaphore.acquire(personId);
    // Acquérir le sémaphore
    setState(() {
      _roomStatus = 'Occupée par Personne $personId';
      if (personId == 1) {
        _person1Status = 'A réservé la salle';
      } else {
        _person2Status = 'A réservé la salle';
      }
    });

    await Future.delayed(Duration(seconds: durationInSeconds));
    // Simuler l'utilisation de la salle

    _semaphore.release(personId); // Libérer le sémaphore
    setState(() {
      _roomStatus = 'Libre';
      if (personId == 1) {
        _person1Status = 'A libéré la salle';
      } else {
        _person2Status = 'A libéré la salle';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réservation de Salle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État de la salle : $_roomStatus',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Personne 1 : $_person1Status',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Personne 2 : $_person2Status',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      () => _reserveRoom(
                        1,
                        5,
                      ), // Personne 1 réserve pour 3 secondes
                  child: Text('Personne 1 Réserve'),
                ),
                ElevatedButton(
                  onPressed:
                      () => _reserveRoom(
                        2,
                        4,
                      ), // Personne 2 réserve pour 2 secondes
                  child: Text('Personne 2 Réserve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Classe Sémaphore personnalisée avec Lock du package synchronized
class Semaphore {
  int _permits;
  final List<Completer<void>> _waiting = [];
  final Lock _lock = Lock(); // Verrou pour garantir l'exclusion mutuelle

  Semaphore(int permits) : _permits = permits;

  Future<void> acquire(int personId) async {
    bool shouldWait = await _lock.synchronized(() async {
      if (_permits > 0) {
        _permits--;
        return false;
      }
      final completer = Completer<void>();
      _waiting.add(completer);
      return true;
    });

    if (shouldWait) {
      await _waiting.last.future;
    }
  }

  void release(int personId) async {
    await _lock.synchronized(() {
      if (_waiting.isNotEmpty) {
        final completer = _waiting.removeAt(0);
        completer.complete();
      } else {
        _permits++;
      }
    });
  }
}
