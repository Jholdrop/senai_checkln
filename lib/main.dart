import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const CheckInApp());

class CheckInApp extends StatelessWidget {
  const CheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF102A43);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SENAI CheckIn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: ink, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class CheckInRecord {
  const CheckInRecord({this.id, required this.dateTime, required this.latitude, required this.longitude, required this.note, this.photoPath});

  final int? id;
  final DateTime dateTime;
  final double latitude;
  final double longitude;
  final String note;
  final String? photoPath;

  Map<String, Object?> toMap() => {
        'data_hora': dateTime.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'observacao': note,
        'caminho_foto': photoPath,
      };

  factory CheckInRecord.fromMap(Map<String, Object?> map) => CheckInRecord(
        id: map['id'] as int,
        dateTime: DateTime.parse(map['data_hora'] as String),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        note: map['observacao'] as String,
        photoPath: map['caminho_foto'] as String?,
      );
}

class CheckInDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'senai_checkin.db');
    _database = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE registros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_hora TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        observacao TEXT NOT NULL,
        caminho_foto TEXT
      )''');
    });
    return _database!;
  }

  static Future<List<CheckInRecord>> all() async {
    final rows = await (await database).query('registros', orderBy: 'data_hora DESC');
    return rows.map(CheckInRecord.fromMap).toList();
  }

  static Future<void> insert(CheckInRecord record) async => (await database).insert('registros', record.toMap());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CheckInRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await CheckInDatabase.all();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  Future<void> _newRecord() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const NewRecordPage()));
    if (saved == true) {
      await _loadRecords();
      await SystemSound.play(SystemSoundType.click);
      if (mounted) _message('Registro salvo com sucesso.', success: true);
    }
  }

  void _message(String text, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: success ? const Color(0xFF19735B) : null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SENAI CheckIn', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Registro de campo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ]),
        actions: [IconButton(onPressed: _loadRecords, tooltip: 'Atualizar registros', icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _newRecord, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Novo registro')),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? ListView(children: [SizedBox(height: MediaQuery.sizeOf(context).height * .2), const Icon(Icons.fact_check_outlined, size: 72, color: Color(0xFF8BA3B5)), SizedBox(height: 16), Center(child: Text('Nenhum registro ainda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))), SizedBox(height: 8), Center(child: Text('Use o botão abaixo para registrar sua presença.'))])
                : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), itemCount: _records.length, itemBuilder: (_, index) => _RecordCard(record: _records[index])),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final CheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final date = '${record.dateTime.day.toString().padLeft(2, '0')}/${record.dateTime.month.toString().padLeft(2, '0')}/${record.dateTime.year}';
    final time = '${record.dateTime.hour.toString().padLeft(2, '0')}:${record.dateTime.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: record.photoPath == null ? const CircleAvatar(radius: 30, child: Icon(Icons.location_on_outlined)) : Image.file(File(record.photoPath!), width: 60, height: 60, fit: BoxFit.cover),
        title: Text(record.note.isEmpty ? 'Registro de presença' : record.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$date às $time\n${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecordDetailPage(record: record))),
      ),
    );
  }
}

class NewRecordPage extends StatefulWidget {
  const NewRecordPage({super.key});
  @override
  State<NewRecordPage> createState() => _NewRecordPageState();
}

class _NewRecordPageState extends State<NewRecordPage> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  Position? _position;
  XFile? _photo;
  bool _busy = false;
  String _status = 'Pronto para iniciar';

  @override
  void dispose() { _noteController.dispose(); super.dispose(); }

  Future<bool> _requestLocation() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) { _show('A permissão de localização é necessária para validar o ponto.'); return false; }
    if (!await Geolocator.isLocationServiceEnabled()) { _show('Ative o GPS do dispositivo e tente novamente.'); return false; }
    try {
      setState(() => _status = 'Obtendo localização...');
      _position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _status = 'Localização capturada');
      return true;
    } catch (_) { _show('Não foi possível obter o GPS agora.'); return false; }
  }

  Future<void> _takePhoto() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) { _show('A permissão da câmera é necessária para anexar uma foto.'); return; }
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 82);
    if (photo != null) setState(() { _photo = photo; _status = 'Foto capturada'; });
  }

  Future<void> _save() async {
    if (_position == null) { _show('Capture a localização antes de salvar.'); return; }
    setState(() => _busy = true);
    await CheckInDatabase.insert(CheckInRecord(dateTime: DateTime.now(), latitude: _position!.latitude, longitude: _position!.longitude, note: _noteController.text.trim(), photoPath: _photo?.path));
    if (mounted) Navigator.of(context).pop(true);
  }

  void _show(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo registro'), actions: [IconButton(onPressed: _busy ? null : _save, tooltip: 'Salvar registro', icon: const Icon(Icons.check))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Valide sua visita', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), const Text('Colete a localização e uma evidência visual do atendimento.'),
        const SizedBox(height: 24),
        _ActionTile(icon: Icons.my_location, title: 'Localização GPS', subtitle: _position == null ? 'Ainda não capturada' : '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}', color: _position == null ? Colors.orange : Colors.green, onTap: _requestLocation),
        const SizedBox(height: 12),
        _ActionTile(icon: Icons.camera_alt_outlined, title: 'Foto da atividade', subtitle: _photo == null ? 'Toque para abrir a câmera' : 'Foto anexada', color: _photo == null ? Colors.orange : Colors.green, onTap: _takePhoto),
        if (_photo != null) ...[const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_photo!.path), height: 190, fit: BoxFit.cover))],
        const SizedBox(height: 20),
        TextField(controller: _noteController, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Observação', hintText: 'Descreva a visita ou atividade...', alignLabelWithHint: true)),
        const SizedBox(height: 18),
        Text(_status, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _busy ? null : _save, icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined), label: Text(_busy ? 'Salvando...' : 'Salvar registro'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: CircleAvatar(backgroundColor: color.withAlpha(35), foregroundColor: color, child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)));
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({super.key, required this.record});
  final CheckInRecord record;

  Future<void> _openMap(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${record.latitude},${record.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o mapa.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalhes do registro')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (record.photoPath != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(record.photoPath!), height: 250, fit: BoxFit.cover)),
          const SizedBox(height: 20),
          Text(record.note.isEmpty ? 'Registro de presença' : record.note, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _DetailRow(icon: Icons.schedule, label: 'Data e hora', value: record.dateTime.toLocal().toString().substring(0, 16)),
          _DetailRow(icon: Icons.pin_drop_outlined, label: 'Coordenadas', value: '${record.latitude}, ${record.longitude}'),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: () => _openMap(context), icon: const Icon(Icons.map_outlined), label: const Text('Abrir localização no mapa')),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}
