import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/pasien_schema.dart';
import '../../logic/pasien_bloc/pasien_bloc.dart';
import '../../logic/pasien_bloc/pasien_event.dart';
import '../../logic/pasien_bloc/pasien_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'pasien_profile_screen.dart';
import 'register_pasien_screen.dart';

/// Patient catalogue with offline search (name, MRN, KTP) over the local Isar
/// store. First stop of the staff flow: list -> profile -> clinical visits.
/// Normally embedded as a shell tab (no Scaffold of its own).
class PasienListScreen extends StatefulWidget {
  const PasienListScreen({super.key});

  @override
  State<PasienListScreen> createState() => _PasienListScreenState();
}

class _PasienListScreenState extends State<PasienListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PasienBloc>().add(const LoadPasienList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) =>
      context.read<PasienBloc>().add(LoadPasienList(query));

  Future<void> _openRegistration() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterPasienScreen()),
    );
    // A patient may have been created while the form was open.
    if (mounted) _search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasienBloc, PasienState>(
      builder: (context, state) {
        final loading = state is PasienLoading;
        final patients = state is PasienListLoaded ? state.pasiens : null;
        final searching =
            state is PasienListLoaded && state.query.trim().isNotEmpty;
        // Returning from registration/profile leaves a single-record state
        // (PasienSuccess); refresh the catalogue once the frame settles.
        if (state is PasienSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context
                  .read<PasienBloc>()
                  .add(LoadPasienList(_searchController.text));
            }
          });
        }
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pasien', style: AppTextStyles.appTitle),
                    IconButton.filled(
                      tooltip: 'Rejistu pasiente foun',
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: loading ? null : _openRegistration,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: _search,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buka pasiente (naran, MRN, KTP)...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: loading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: AppSpacing.sm),
                              Text('Maka dadus pasiente...'),
                            ],
                          ),
                        )
                      : state is PasienError
                          ? const Center(
                              child: Text(
                                'Dadus pasiente la konsege maka.',
                                style: AppTextStyles.error,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : patients == null
                              ? const SizedBox.shrink()
                              : patients.isEmpty
                                  ? Center(
                                      child: Text(
                                        searching
                                            ? 'La hetan pasiente ho lian neba.'
                                            : 'Seidauk iha dadus pasiente.',
                                        style: AppTextStyles.body,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () async =>
                                          _search(_searchController.text),
                                      child: ListView.separated(
                                        itemCount: patients.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                        itemBuilder: (context, index) =>
                                            _PatientCard(
                                          pasien: patients[index],
                                        ),
                                      ),
                                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.pasien});

  final Pasien pasien;

  String get _birthDate =>
      '${pasien.tanggalLahir.day.toString().padLeft(2, '0')}/'
      '${pasien.tanggalLahir.month.toString().padLeft(2, '0')}/'
      '${pasien.tanggalLahir.year}';

  @override
  Widget build(BuildContext context) {
    final gender = pasien.jenisKelamin == 'Perempuan' ? 'Feto' : 'Mane';
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PasienProfileScreen(pasien: pasien),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              pasien.namaLengkap.isNotEmpty
                  ? pasien.namaLengkap[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pasien.namaLengkap,
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'MRN: ${pasien.medicalRecordNumber ?? '-'}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Moris: $_birthDate  |  $gender',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
