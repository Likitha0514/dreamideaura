
import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../data/services/backup_restore_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final BackupRestoreService _backupService;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _backupService = BackupRestoreService(LocalJsonStorage());
  }

  Future<bool> _showConfirmation({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _saveBackup() async {
    setState(() => _isProcessing = true);

    try {
      final path = await _backupService.saveBackup();

      if (!mounted) return;

      if (path == null) {
        _showMessage('Backup saving was cancelled.');
      } else {
        _showMessage('Backup saved successfully.');
      }
    } catch (error) {
      _showMessage('Unable to save backup: $error');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveBackupAndReset() async {
    final confirmed = await _showConfirmation(
      title: 'Save Backup & Reset App?',
      message:
          'A complete backup will be saved first. Only after it is '
          'successfully saved, all members, investments and products '
          'will be cleared and profit percentages will return to '
          '40% / 40% / 20%.\n\n'
          'Make sure you keep the backup file safely.',
      confirmText: 'Continue',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final path = await _backupService.saveBackup();

      if (!mounted) return;

      if (path == null) {
        _showMessage(
          'Backup was not saved. Your app data has not been reset.',
        );
        return;
      }

      // Reset is allowed only after saveBackup returns a saved path.
      await _backupService.resetAppData();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      _showMessage(
        'Unable to complete reset. Your backup may still be available. '
        'Please check before trying again. Error: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isProcessing = true);

    try {
      // Read and validate the complete backup before asking to replace
      // the current data.
      final backupData =
          await _backupService.pickAndValidateBackup();

      if (!mounted) return;

      if (backupData == null) {
        _showMessage('Restore was cancelled.');
        return;
      }

      final confirmed = await _showConfirmation(
        title: 'Restore Backup?',
        message:
            'This will replace all current members, profit settings, '
            'investments and products with the selected backup data.\n\n'
            'This action cannot be undone. Continue?',
        confirmText: 'Restore',
      );

      if (!confirmed || !mounted) return;

      await _backupService.restoreBackup(backupData);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      _showMessage(
        'Unable to restore backup. Your current data has not been '
        'replaced. Please check the selected file.\n$error',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Keep your business data safe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save a copy of your members, investments, products '
                'and profit configuration. You can restore this data '
                'whenever needed.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildActionCard(
                icon: Icons.download_outlined,
                color: const Color(0xFF00A896),
                title: 'Save Backup',
                description:
                    'Export all your current app data into a JSON '
                    'file. Your existing data will remain unchanged.',
                buttonText: 'Save Backup',
                onPressed: _saveBackup,
              ),
              _buildActionCard(
                icon: Icons.restore_outlined,
                color: const Color(0xFF2563EB),
                title: 'Restore Backup',
                description:
                    'Choose a previously saved DreamsIdeAura JSON '
                    'backup to replace your current app data.',
                buttonText: 'Choose Backup & Restore',
                onPressed: _restoreBackup,
              ),
              _buildActionCard(
                icon: Icons.restart_alt,
                color: const Color(0xFFD97706),
                title: 'Save Backup & Reset App',
                description:
                    'Save a complete backup first. Then clear all '
                    'members, investments and products and reset '
                    'profit percentages to 40% / 40% / 20%.',
                buttonText: 'Save Backup & Reset',
                onPressed: _saveBackupAndReset,
              ),
              const SizedBox(height: 8),
              const Text(
                'Important: Keep your backup JSON file in a safe '
                'location. Restoring a backup replaces your current '
                'business data.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
