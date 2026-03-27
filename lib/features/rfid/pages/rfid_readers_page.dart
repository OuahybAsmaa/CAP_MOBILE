import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rfid_provider.dart';
import '../models/rfid_reader_model.dart';
import 'epc_write_page.dart';

class RfidReadersPage extends ConsumerWidget {
  const RfidReadersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rfidState = ref.watch(rfidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecteurs RFID Zebra'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: rfidState.isLoading
                ? null
                : () => ref.read(rfidProvider.notifier).loadAvailableReaders(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(context, rfidState, ref),
          if (rfidState.error != null) _buildErrorBanner(rfidState.error!),
          if (rfidState.message != null) _buildMessageBanner(rfidState.message!),

          if (rfidState.connectedReader != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Aller à l\'écriture EPC →',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EpcWritePage(),
                      ),
                    );
                  },
                ),
              ),
            ),

          Expanded(child: _buildContent(context, ref, rfidState)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, RfidState state, WidgetRef ref) {
    final isConnected = state.connectedReader != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isConnected ? Colors.green[100] : Colors.grey[200],
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.nfc : Icons.nfc_outlined,
            color: isConnected ? Colors.green : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConnected
                  ? '✅ Connecté : ${state.connectedReader!.name}'
                  : '⚪ Aucun lecteur connecté',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (isConnected)
            TextButton.icon(
              icon: state.isLoading
                  ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.red,
                ),
              )
                  : const Icon(Icons.link_off, color: Colors.red),
              label: const Text(
                'Déconnecter',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(rfidProvider.notifier).disconnectReader(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red[100],
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.green[100],
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, RfidState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche des lecteurs RFID...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (state.availableReaders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun lecteur RFID détecté',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que le lecteur est allumé',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Rechercher à nouveau'),
              onPressed: () =>
                  ref.read(rfidProvider.notifier).loadAvailableReaders(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lecteurs disponibles :',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.availableReaders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.availableReaders.length,
            itemBuilder: (context, index) {
              final reader = state.availableReaders[index];
              return _buildReaderCard(context, ref, reader, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReaderCard(
      BuildContext context,
      WidgetRef ref,
      RfidReaderModel reader,
      RfidState state,
      ) {
    final isConnected = state.connectedReader?.name == reader.name;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isConnected ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isConnected
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? Colors.green
              : (state.isLoading ? Colors.grey : Colors.blue),
          child: state.isLoading && !isConnected
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2,
            ),
          )
              : const Icon(Icons.nfc, color: Colors.white),
        ),
        title: Text(
          reader.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: state.isLoading ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text('Adresse : ${reader.address}'),
        trailing: isConnected
            ? const Chip(
          label: Text('Connecté', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        )
            : SizedBox(
          width: 110,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              state.isLoading ? Colors.grey[400] : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: state.isLoading
                ? null
                : () => ref
                .read(rfidProvider.notifier)
                .connectToReader(reader),
            child: state.isLoading
                ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 6),
                Text('...', style: TextStyle(color: Colors.white)),
              ],
            )
                : const Text(
              'Connecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}