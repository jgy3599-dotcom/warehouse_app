import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';


class StockAddScreen extends StatefulWidget {
  const StockAddScreen({super.key});

  @override
  State<StockAddScreen> createState() => _StockAddScreenState();
}

class _StockAddScreenState extends State<StockAddScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController specController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController makerController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController orderCodeController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final format = NumberFormat('#,###');

  int get totalPrice {
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    final unit = int.tryParse(unitPriceController.text.trim()) ?? 0;
    return qty * unit;
  }

  // CSV 파일에서 law데이터 등록 함수
  Future<void> _pickAndUploadCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final rows = const LineSplitter().convert(content);

      int successCount = 0;
      int failCount = 0;
      List<String> errorLines = [];


      // CSV 헤더 예시:
      // 날짜,대분류,구분,자재이름,설명,제조사,수량,단가,총금액,상태,발주코드,비고

      for (var i = 1; i < rows.length; i++) { // 첫줄은 헤더라고 가정
        final columns = rows[i].split(',');
        if (columns.length >= 13) { // 설명까지 포함
          try {
            await FirebaseFirestore.instance.collection('laws').add({
              '날짜': columns[0].trim(),
              '대분류': columns[1].trim(),
              '구분': columns[2].trim(),
              '규격': columns[3].trim(),
              '자재이름': columns[4].trim(),
              '설명': columns[5].trim(),
              '제조사': columns[6].trim(),
              '수량': int.tryParse(columns[7].trim()) ?? 0,
              '단가': int.tryParse(columns[8].trim()) ?? 0,
              '총금액': int.tryParse(columns[9].trim()) ?? 0,
              '상태': columns[10].trim(),
              '발주코드': columns[11].trim(),
              '비고': columns[12].trim(),
            });
            successCount++;
          } catch (e) {
            failCount++;
            errorLines.add('${i + 1}행: DB 저장 오류 (${e.toString().split('\n').first})');
          }
        } else {
          failCount++;
          errorLines.add('${i + 1}행: 컬럼 개수 부족');
        }
      }

      if (!context.mounted) return;
      String message = 'CSV 업로드 결과: 성공 $successCount건, 실패 $failCount건';
      if (errorLines.isNotEmpty) {
        message += '\n에러:\n${errorLines.join('\n')}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 13)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }


  void _addLawData() async {
    // 입력값 수집
    final date = dateController.text.trim();
    final category = categoryController.text.trim();
    final type = typeController.text.trim();
    final spec = specController.text.trim();
    final name = nameController.text.trim();
    final desc = descController.text.trim();
    final maker = makerController.text.trim();
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    final unitPrice = int.tryParse(unitPriceController.text.trim()) ?? 0;
    final totalPrice = this.totalPrice;
    final status = statusController.text.trim();
    final orderCode = orderCodeController.text.trim();
    final note = noteController.text.trim();


    // 필수값 체크 (필요시 추가)
    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자재이름과 수량을 올바르게 입력하세요')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('laws').add({
      '날짜': date,
      '대분류': category,
      '구분': type,
      '규격': spec,
      '자재이름': name,
      '설명' : desc,
      '제조사': maker,
      '수량': qty,
      '단가': unitPrice,
      '총금액': totalPrice,
      '상태': status,
      '발주코드': orderCode,
      '비고': note,
    });
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등록 완료!')),
    );
    // 입력값 초기화
    dateController.clear();
    categoryController.clear();
    typeController.clear();
    specController.clear();
    nameController.clear();
    descController.clear();
    makerController.clear();
    qtyController.clear();
    unitPriceController.clear();
    statusController.clear();
    orderCodeController.clear();
    noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Law데이터 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: dateController, decoration: const InputDecoration(labelText: '날짜 (예: 2024-07-28)')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: '대분류')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: '구분')),
            TextField(controller: specController, decoration: const InputDecoration(labelText: '규격')),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '자재이름')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: '설명' )),
            TextField(controller: makerController, decoration: const InputDecoration(labelText: '제조사')),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '수량'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: unitPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '단가'),
              onChanged: (_) => setState(() {}),
            ),
            Row(
              children: [
                const Text('총금액: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${format.format(totalPrice)} 원'), // 콤마 표시
              ],
            ),
            TextField(controller: statusController, decoration: const InputDecoration(labelText: '상태')),
            TextField(controller: orderCodeController, decoration: const InputDecoration(labelText: '발주코드')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: '비고')),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addLawData,
                    child: const Text('등록'),
                  ),
                ),
                const SizedBox(width: 10), // 버튼 사이 간격
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickAndUploadCsv(context),
                    child: const Text('CSV 파일로 업로드'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
