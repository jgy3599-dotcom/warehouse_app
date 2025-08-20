import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsageLogScreen extends StatefulWidget {
  const UsageLogScreen({super.key});

  @override
  State<UsageLogScreen> createState() => _UsageLogScreenState();
}

class _UsageLogScreenState extends State<UsageLogScreen> {
  final _dateFmt = DateFormat('yyyy-MM-dd');

  // ✅ 명시적 컨트롤러(세로/가로)
  late final ScrollController _vController;
  late final ScrollController _hController;

  bool get _isDesktop {
    final p = defaultTargetPlatform;
    return !kIsWeb &&
        (p == TargetPlatform.windows ||
            p == TargetPlatform.linux ||
            p == TargetPlatform.macOS);
  }

  Future<QuerySnapshot<Map<String, dynamic>>>? _desktopFuture;

  @override
  void initState() {
    super.initState();
    _vController = ScrollController();
    _hController = ScrollController();
    if (_isDesktop) _reloadDesktop();
  }

  @override
  void dispose() {
    _vController.dispose();
    _hController.dispose();
    super.dispose();
  }

  void _reloadDesktop() {
    _desktopFuture = FirebaseFirestore.instance
        .collection('usage_logs')
        .orderBy('날짜', descending: true)
        .get();
    setState(() {});
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) return _dateFmt.format(v.toDate());
    return v.toString();
  }

  Widget _buildTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text('사용이력이 없습니다.'));
    }

    // ✅ Scrollbar ↔ ScrollView 동일 컨트롤러 사용 + primary:false
    return Scrollbar(
      controller: _vController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vController,
        primary: false,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _hController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _hController,
            primary: false,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('날짜')),
                DataColumn(label: Text('자재이름')),
                DataColumn(label: Text('사용수량')),
                DataColumn(label: Text('사용위치')),
                DataColumn(label: Text('설비ID')),
                DataColumn(label: Text('사유')),
              ],
              rows: docs.map((doc) {
                final item = doc.data();
                return DataRow(
                  cells: [
                    DataCell(Text(_fmtDate(item['날짜']))),
                    DataCell(Text(
                      (item['law_name'] ?? item['자재이름'] ?? '').toString(),
                    )),
                    DataCell(Text(item['사용수량']?.toString() ?? '')),
                    DataCell(Text(item['사용위치']?.toString() ?? '')),
                    DataCell(Text(item['설비ID']?.toString() ?? '')),
                    DataCell(SizedBox(
                      width: 280,
                      child: Text(
                        item['사유']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyDesktop() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _desktopFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('사용이력이 없습니다.'));
        }
        return _buildTable(data.docs);
      },
    );
  }

  Widget _buildBodyLive() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('usage_logs')
          .orderBy('날짜', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.docs.isEmpty) {
          return const Center(child: Text('사용이력이 없습니다.'));
        }
        return _buildTable(data.docs);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자재 사용이력'),
        actions: _isDesktop
            ? [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadDesktop,
          )
        ]
            : null,
      ),
      body: _isDesktop ? _buildBodyDesktop() : _buildBodyLive(),
    );
  }
}
