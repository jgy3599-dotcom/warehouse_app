import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LawEditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const LawEditScreen({super.key, required this.docId, required this.data});

  @override
  State<LawEditScreen> createState() => _LawEditScreenState();
}

class _LawEditScreenState extends State<LawEditScreen> {
  late final TextEditingController dateController;
  late final TextEditingController categoryController;
  late final TextEditingController typeController;
  late final TextEditingController specController;
  late final TextEditingController nameController;
  late final TextEditingController descController;
  late final TextEditingController makerController;
  late final TextEditingController qtyController;
  late final TextEditingController unitPriceController;
  late final TextEditingController statusController;
  late final TextEditingController orderCodeController;
  late final TextEditingController noteController;

  // ✅ 세로 스크롤 컨트롤러 (Scrollbar와 동일 컨트롤러 사용)
  late final ScrollController _vController;

  final _numFmt = NumberFormat('#,###');
  final _dateFmt = DateFormat('yyyy-MM-dd');
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _vController = ScrollController();

    final d = widget.data;

    // ✅ 로컬 함수명 언더스코어 제거 (lint 해결)
    String initDateText(dynamic v) {
      if (v == null) return '';
      if (v is Timestamp) return _dateFmt.format(v.toDate());
      return v.toString();
    }

    String initNumText(dynamic v) {
      if (v == null) return '';
      if (v is num) return v.toString();
      final cleaned = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
      return cleaned;
    }

    dateController = TextEditingController(text: initDateText(d['날짜']));
    categoryController = TextEditingController(text: (d['대분류'] ?? '').toString());
    typeController = TextEditingController(text: (d['구분'] ?? '').toString());
    specController = TextEditingController(text: (d['규격'] ?? '').toString());
    nameController = TextEditingController(text: (d['자재이름'] ?? '').toString());
    descController = TextEditingController(text: (d['설명'] ?? '').toString());
    makerController = TextEditingController(text: (d['제조사'] ?? '').toString());
    qtyController = TextEditingController(text: initNumText(d['수량']));
    unitPriceController = TextEditingController(text: initNumText(d['단가']));
    statusController = TextEditingController(text: (d['상태'] ?? '').toString());
    orderCodeController = TextEditingController(text: (d['발주코드'] ?? '').toString());
    noteController = TextEditingController(text: (d['비고'] ?? '').toString());
  }

  @override
  void dispose() {
    dateController.dispose();
    categoryController.dispose();
    typeController.dispose();
    specController.dispose();
    nameController.dispose();
    descController.dispose();
    makerController.dispose();
    qtyController.dispose();
    unitPriceController.dispose();
    statusController.dispose();
    orderCodeController.dispose();
    noteController.dispose();

    _vController.dispose();
    super.dispose();
  }

  int _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  int get totalPrice {
    final qty = _parseInt(qtyController.text.trim());
    final unit = _parseInt(unitPriceController.text.trim());
    return qty * unit;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = () {
      try {
        if (dateController.text.trim().isEmpty) return now;
        return _dateFmt.parse(dateController.text.trim());
      } catch (_) {
        return now;
      }
    }();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      dateController.text = _dateFmt.format(picked);
    });
  }

  Future<void> _updateLawData() async {
    if (_saving) return;

    setState(() => _saving = true);

    // await 전에 레퍼런스 캐싱 (use_build_context_synchronously 방지)
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // ✅ 로컬 함수명 언더스코어 제거
    dynamic saveDateValue() {
      final orig = widget.data['날짜'];
      final text = dateController.text.trim();
      if (orig is Timestamp) {
        try {
          final dt = _dateFmt.parse(text);
          return Timestamp.fromDate(dt);
        } catch (_) {
          return orig; // 파싱 실패 시 기존값 유지
        }
      } else {
        return text; // 문자열로 관리 중이면 문자열 저장
      }
    }

    final payload = {
      '날짜': saveDateValue(),
      '대분류': categoryController.text.trim(),
      '구분': typeController.text.trim(),
      '규격': specController.text.trim(),
      '자재이름': nameController.text.trim(),
      '설명': descController.text.trim(),
      '제조사': makerController.text.trim(),
      '수량': _parseInt(qtyController.text.trim()),
      '단가': _parseInt(unitPriceController.text.trim()),
      '총금액': totalPrice,
      '상태': statusController.text.trim(),
      '발주코드': orderCodeController.text.trim(),
      '비고': noteController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('laws')
          .doc(widget.docId)
          .update(payload);

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('수정 완료!')));
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {Widget? suffix}) =>
      InputDecoration(labelText: label, suffixIcon: suffix);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('law데이터 수정'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Scrollbar(
        controller: _vController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _vController,
          primary: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: _dec(
                  '날짜',
                  suffix: IconButton(
                    tooltip: '날짜 선택',
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: categoryController, decoration: _dec('대분류')),
              const SizedBox(height: 12),
              TextField(controller: typeController, decoration: _dec('구분')),
              const SizedBox(height: 12),
              TextField(controller: specController, decoration: _dec('규격')),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: _dec('자재이름')),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: _dec('설명'), maxLines: 3),
              const SizedBox(height: 12),
              TextField(controller: makerController, decoration: _dec('제조사')),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('수량'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('단가'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('총금액: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_numFmt.format(totalPrice)} 원'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: statusController, decoration: _dec('상태')),
              const SizedBox(height: 12),
              TextField(controller: orderCodeController, decoration: _dec('발주코드')),
              const SizedBox(height: 12),
              TextField(controller: noteController, decoration: _dec('비고'), maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _updateLawData,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
