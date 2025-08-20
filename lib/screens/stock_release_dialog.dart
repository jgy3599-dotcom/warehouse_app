import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockReleaseDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;
  const StockReleaseDialog({super.key, required this.docId, required this.item});

  @override
  State<StockReleaseDialog> createState() => _StockReleaseDialogState();
}

class _StockReleaseDialogState extends State<StockReleaseDialog> {
  final qtyController = TextEditingController();
  final placeController = TextEditingController();
  final equipIdController = TextEditingController();
  final reasonController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    qtyController.dispose();
    placeController.dispose();
    equipIdController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _releaseStock() async {
    final usedQty = int.tryParse(qtyController.text.trim()) ?? 0;
    if (usedQty <= 0 || usedQty > (widget.item['수량'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출고 수량을 확인하세요!')),
      );
      return;
    }
    setState(() => isLoading = true);

    try {
      // 1. 현재수량을 Firestore에서 직접 읽음
      final docRef = FirebaseFirestore.instance.collection('laws').doc(widget.docId);
      final docSnap = await docRef.get();
      final currQty = docSnap['수량'] ?? 0;
      if (currQty < usedQty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('재고 부족!')),
        );
        return;
      }

      // 2. Firestore에 수량 업데이트
      await docRef.update({'수량': currQty - usedQty});

      // 3. 사용이력 로그 저장
      final logRef = FirebaseFirestore.instance.collection('usage_logs').doc();
      await logRef.set({
        'law_doc_id': widget.docId,
        'law_name': widget.item['자재이름'] ?? '',
        '날짜': DateTime.now().toIso8601String(),
        '사용수량': usedQty,
        '사용위치': placeController.text.trim(),
        '설비ID': equipIdController.text.trim(),
        '사유': reasonController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출고 처리 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출고 중 오류 발생: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('자재 출고'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('현재수량: ${widget.item['수량'] ?? ''}'),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '출고 수량'),
            ),
            TextField(
              controller: placeController,
              decoration: const InputDecoration(labelText: '사용위치'),
            ),
            TextField(
              controller: equipIdController,
              decoration: const InputDecoration(labelText: '설비ID'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '사유'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _releaseStock,
          child: isLoading ? const CircularProgressIndicator() : const Text('출고'),
        ),
      ],
    );
  }
}
