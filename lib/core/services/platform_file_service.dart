import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/savings_goal_model.dart';
import '../../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../utils/platform_info.dart';

class PickedMemoryFile {
  const PickedMemoryFile({
    required this.name,
    required this.bytes,
    required this.sizeInBytes,
    this.extension,
  });

  final String name;
  final Uint8List bytes;
  final int sizeInBytes;
  final String? extension;
}

/// Cross-platform file upload/download service that works on both Mobile (iOS/Android)
/// and Web without ever touching `dart:io` `File(path)`.
///
/// Always reads and writes raw `Uint8List` bytes.
class PlatformFileService {
  const PlatformFileService();

  /// Opens the native or web file picker and returns raw `Uint8List` bytes.
  Future<PickedMemoryFile?> pickImageOrDocumentBytes({
    List<String> allowedExtensions = const ['png', 'jpg', 'jpeg', 'pdf'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true, // Crucial for Flutter Web & cross-platform byte access
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return null;

      return PickedMemoryFile(
        name: file.name,
        bytes: bytes,
        sizeInBytes: file.size,
        extension: file.extension,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates and downloads a Njangi Goal Statement / Transaction Receipt as
  /// raw UTF-8 bytes across Web (triggers browser download) and Mobile.
  Future<bool> exportGoalStatement({
    required SavingsGoal goal,
    required List<NjangiTransaction> transactions,
  }) async {
    final buffer = StringBuffer()
      ..writeln('====================================================')
      ..writeln('           NJANGISAVE CONTRIBUTION STATEMENT        ')
      ..writeln('   "Save little by little today, be ready on time"  ')
      ..writeln('====================================================')
      ..writeln('Goal Name          : ${goal.name}')
      ..writeln(
        'Target Amount      : ${AppFormatters.formatCurrency(goal.targetAmount)}',
      )
      ..writeln(
        'Verified Saved     : ${AppFormatters.formatCurrency(goal.amountSaved)} (${goal.progressPercent}%)',
      )
      ..writeln(
        'Remaining Amount   : ${AppFormatters.formatCurrency(goal.remainingAmount)}',
      )
      ..writeln(
        'Platform Fee       : ${AppFormatters.formatCurrency(goal.platformFee)} (Separate)',
      )
      ..writeln(
        'Contribution Date  : ${AppFormatters.formatDate(goal.dueDate)}',
      )
      ..writeln('Savings Lock       : ${goal.lockStatus.label}')
      ..writeln('----------------------------------------------------')
      ..writeln('VERIFIED FAPSHI TRANSACTIONS:')
      ..writeln('----------------------------------------------------');

    if (transactions.isEmpty) {
      buffer.writeln('No transactions recorded for this goal yet.');
    } else {
      for (final tx in transactions) {
        buffer.writeln(
          '[${AppFormatters.formatDateTime(tx.createdAt)}] '
          'Ref: ${tx.reference} | ${tx.type.label} | '
          '${AppFormatters.formatCurrency(tx.amount)} | '
          'Status: ${tx.status.fapshiStatusCode}',
        );
      }
    }
    buffer.writeln('====================================================');

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final safeName = goal.name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return PlatformInfo.saveBytesAsFile(
      fileName: 'njangisave_${safeName}_statement.txt',
      bytes: bytes,
      mimeType: 'text/plain',
    );
  }
}

final platformFileServiceProvider = Provider<PlatformFileService>((ref) {
  return const PlatformFileService();
});
