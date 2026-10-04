import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/pasien_schema.dart';
import '../../logic/pasien_bloc/pasien_bloc.dart';
import '../../logic/pasien_bloc/pasien_event.dart';
import '../../logic/pasien_bloc/pasien_state.dart';
import '../widgets/status_indicator.dart';
import 'pasien_profile_screen.dart';

/// Patient registration form. Opened from the patient list (+); after a
/// successful local save it replaces itself with the new patient's profile,
/// so back from the profile returns straight to the list.
class RegisterPasienScreen extends StatefulWidget {
  const RegisterPasienScreen({super.key});

  @override
  State<RegisterPasienScreen> createState() => _RegisterPasienScreenState();
}

class _RegisterPasienScreenState extends State<RegisterPasienScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ktp = TextEditingController();
  final _name = TextEditingController();
  final _birthPlace = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Laki-laki';
  String? _fingerprintHash;
  String _status = 'Pending';

  @override
  void dispose() {
    _ktp.dispose();
    _name.dispose();
    _birthPlace.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label tenke prenxe.';
    }
    return null;
  }

  void _scanFingerprint() {
    final source = '${_ktp.text}:${_name.text}:${DateTime.now().microsecondsSinceEpoch}';
    final hash = source.codeUnits.fold<int>(17, (value, unit) => value * 31 + unit);
    setState(() => _fingerprintHash = hash.toRadixString(16));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometria simulasaun rejistadu.')),
    );
  }

  Future<void> _chooseBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(1990),
      helpText: 'Hili data moris',
      cancelText: 'Kansela',
      confirmText: 'Hili',
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favor prenxe dadus pasiente hotu.')),
      );
      return;
    }
    final pasien = Pasien()
      ..noKtp = _ktp.text.trim()
      ..namaLengkap = _name.text.trim()
      ..tanggalLahir = _birthDate!
      ..tempatLahir = _birthPlace.text.trim()
      ..jenisKelamin = _gender
      ..fingerprintHash = _fingerprintHash
      ..localStatus = 'Pending';
    context.read<PasienBloc>().add(RegisterPasien(pasien));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasienBloc, PasienState>(
      listener: (context, state) {
        if (state is PasienSuccess) {
          setState(() => _status = state.pasien.localStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.pasien.localStatus == 'Synced'
                  ? 'Dados pasiente rejistradu ho susesu!'
                  : 'Dados rai hela lokal. Sinkroniza bainhira koneksaun fila.'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => PasienProfileScreen(pasien: state.pasien),
            ),
          );
        }
        if (state is PasienError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is PasienLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Rejistu Pasiente Foun')),
          body: Form(
            key: _formKey,
            child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Rejistu Pasiente Foun', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Dadus sei rai lokal uluk atu aplikasaun kontinua funsiona bainhira offline.'),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: StatusIndicator(status: _status)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ktp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Numeru KTP'),
                validator: (value) => _required(value, 'Numeru KTP'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Naran kompletu'),
                validator: (value) => _required(value, 'Naran kompletu'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthPlace,
                decoration: const InputDecoration(labelText: 'Fatin moris'),
                validator: (value) => _required(value, 'Fatin moris'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_birthDate == null
                    ? 'Data moris'
                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                leading: const Icon(Icons.calendar_month),
                trailing: FilledButton.tonal(
                  onPressed: _chooseBirthDate,
                  child: const Text('Hili'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Jéneru'),
                items: const [
                  DropdownMenuItem(value: 'Laki-laki', child: Text('Mane')),
                  DropdownMenuItem(value: 'Perempuan', child: Text('Feto')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? _gender),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _scanFingerprint,
                icon: const Icon(Icons.fingerprint),
                label: Text(_fingerprintHash == null
                    ? 'Scan Fingerprint (Simulasaun)'
                    : 'Fingerprint rejistadu'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: loading ? null : _submit,
                icon: loading
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Rejista Pasiente'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.read<PasienBloc>().add(const SyncPendingPasien()),
                child: const Text('Sinkroniza Dadus Pendentes'),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
