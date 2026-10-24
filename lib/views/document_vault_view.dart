import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';
import '../widgets/empty_state_card.dart';

class DocumentVaultView extends ConsumerStatefulWidget {
  const DocumentVaultView({super.key});

  @override
  ConsumerState<DocumentVaultView> createState() => _DocumentVaultViewState();
}

class _DocumentVaultViewState extends ConsumerState<DocumentVaultView> {
  List<Map<String, String>> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final list = await StorageService.loadReceipts();
    setState(() {
      _receipts = list;
      _isLoading = false;
    });
  }

  Future<void> _uploadNewDocument() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _showAttachmentDetailsDialog(picked.path);
      }
    } catch (_) {}
  }

  void _showAttachmentDetailsDialog(String path) {
    final symbolController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attach Trade Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(
                  labelText: 'Stock Symbol',
                  hintText: 'e.g. NABIL, SHIVM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Document Note / TMS Order No',
                  hintText: 'e.g. Broker 58 Purchase Bill',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final symbol = symbolController.text.trim().toUpperCase();
                final note = noteController.text.trim();
                final now = DateTime.now().toIso8601String().split('T')[0];

                final newEntry = {
                  'id': 'DOC-${DateTime.now().millisecondsSinceEpoch}',
                  'symbol': symbol.isNotEmpty ? symbol : 'GENERAL',
                  'note': note.isNotEmpty ? note : 'Trade Receipt',
                  'imagePath': path,
                  'date': now,
                };

                final navigator = Navigator.of(context);
                final updated = [_newEntryToMap(newEntry), ..._receipts];
                await StorageService.saveReceipts(updated);
                if (!mounted) return;
                setState(() {
                  _receipts = updated;
                });
                navigator.pop();
              },
              child: const Text('Save to Vault'),
            ),
          ],
        );
      },
    );
  }

  Map<String, String> _newEntryToMap(Map<String, String> entry) => entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document & Receipt Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Upload Document / Bill',
            onPressed: _uploadNewDocument,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receipts.isEmpty
          ? Center(
              child: EmptyStateCard(
                icon: Icons.receipt_long_outlined,
                title: 'Document Vault is Empty',
                message: 'Keep contract notes, TMS buy bills, and chart analysis screenshots organized on this device. Vault files are not encrypted by the app.',
                buttonLabel: 'Upload First Document',
                onButtonPressed: _uploadNewDocument,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _receipts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = _receipts[index];
                final imagePath = item['imagePath'] ?? '';
                final symbol = item['symbol'] ?? 'NEPSE';
                final note = item['note'] ?? '';
                final date = item['date'] ?? '';

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showImageZoomModal(item, theme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: theme.colorScheme.surface,
                            child:
                                imagePath.isNotEmpty &&
                                    File(imagePath).existsSync()
                                ? Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.receipt_long,
                                      size: 40,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    symbol,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(128),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showImageZoomModal(Map<String, String> item, ThemeData theme) {
    final imagePath = item['imagePath'] ?? '';
    final symbol = item['symbol'] ?? '';
    final note = item['note'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text('$symbol Document Preview'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (imagePath.isNotEmpty && File(imagePath).existsSync())
                InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    height: 350,
                  ),
                )
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text('No preview available for this document'),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${item['date']}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
