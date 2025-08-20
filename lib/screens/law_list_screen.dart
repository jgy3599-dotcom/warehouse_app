import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'law_edit_screen.dart';
import 'package:intl/intl.dart';

class LawListScreen extends StatefulWidget {
  const LawListScreen({super.key});

  @override
  State<LawListScreen> createState() => _LawListScreenState();
}

class _LawListScreenState extends State<LawListScreen> {
  final TextEditingController searchController = TextEditingController();
  final NumberFormat format = NumberFormat('#,###');

  String searchText = '';
  DateTime? _lastSearchChange;

  // ✅ 세로/가로 스크롤 컨트롤러
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
    searchController.dispose();
    _vController.dispose();
    _hController.dispose();
    super.dispose();
  }

  void _reloadDesktop() {
    _desktopFuture = FirebaseFirestore.instance.collection('laws').get();
    setState(() {});
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    if (searchText.isEmpty) return true;
    final s = searchText.toLowerCase();
    bool has(dynamic v) => (v?.toString().toLowerCase().contains(s) ?? false);

    return has(item['자재이름']) ||
        has(item['설명']) ||
        has(item['대분류']) ||
        has(item['구분']) ||
        has(item['규격']) ||
        has(item['제조사']) ||
        has(item['상태']) ||
        has(item['발주코드']) ||
        has(item['비고']);
  }

  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) {
      final cleaned = v.replaceAll(',', '').replaceAll('원', '').trim();
      return num.tryParse(cleaned);
    }
    return null;
  }

  String _fmtNum(dynamic v) {
    final n = _asNum(v);
    return n == null ? '' : '${format.format(n)}원';
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(v.toDate());
    }
    return v.toString();
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '검색어 입력 (자재이름/설명/대분류/구분/제조사 등)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchText = '';
                      searchController.clear();
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _lastSearchChange = DateTime.now();
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (_lastSearchChange != null &&
                      DateTime.now()
                          .difference(_lastSearchChange!)
                          .inMilliseconds >=
                          200) {
                    if (!mounted) return;
                    setState(() {
                      searchText = value;
                    });
                  }
                });
              },
            ),
          ),
          if (_isDesktop) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '새로고침(데스크톱: 단발 조회)',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _reloadDesktop,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    // 🔎 필터링
    final filtered = docs.where((doc) => _matchesSearch(doc.data())).toList();
    if (filtered.isEmpty) {
      // ❗ Scrollbar를 만들지 않음 → 컨트롤러 미부착 에러 방지
      return const Center(child: Text('검색 결과 없음'));
    }

    // ✅ Scrollbar와 ScrollView에 동일 컨트롤러 연결 + primary:false
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
                DataColumn(label: Text('대분류')),
                DataColumn(label: Text('구분')),
                DataColumn(label: Text('규격')),
                DataColumn(label: Text('자재이름')),
                DataColumn(label: Text('설명')),
                DataColumn(label: Text('제조사')),
                DataColumn(label: Text('수량')),
                DataColumn(label: Text('단가')),
                DataColumn(label: Text('총금액')),
                DataColumn(label: Text('상태')),
                DataColumn(label: Text('발주코드')),
                DataColumn(label: Text('비고')),
                DataColumn(label: Text('수정/삭제')),
              ],
              rows: filtered.map((doc) {
                final item = doc.data();
                final qty = item['수량']?.toString() ?? '';
                final unitPrice = _fmtNum(item['단가']);
                final total = _fmtNum(item['총금액']);

                return DataRow(
                  cells: [
                    DataCell(Text(_fmtDate(item['날짜']))),
                    DataCell(Text(item['대분류']?.toString() ?? '')),
                    DataCell(Text(item['구분']?.toString() ?? '')),
                    DataCell(Text(item['규격']?.toString() ?? '')),
                    DataCell(Text(item['자재이름']?.toString() ?? '')),
                    DataCell(SizedBox(
                      width: 260,
                      child: Text(
                        item['설명']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                    DataCell(Text(item['제조사']?.toString() ?? '')),
                    DataCell(Text(qty)),
                    DataCell(Text(unitPrice)),
                    DataCell(Text(total)),
                    DataCell(Text(item['상태']?.toString() ?? '')),
                    DataCell(Text(item['발주코드']?.toString() ?? '')),
                    DataCell(SizedBox(
                      width: 220,
                      child: Text(
                        item['비고']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: '수정',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LawEditScreen(
                                  docId: doc.id,
                                  data: item,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: '삭제',
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('정말 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, true),
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;

                            try {
                              await FirebaseFirestore.instance
                                  .collection('laws')
                                  .doc(doc.id)
                                  .delete();

                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('삭제 완료!')),
                              );
                              if (_isDesktop) _reloadDesktop();
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('삭제 실패: $e')),
                              );
                            }
                          },
                        ),
                      ],
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
        if (data == null || data.docs.isEmpty) {
          return const Center(child: Text('데이터 없음'));
        }
        return _buildTable(data.docs);
      },
    );
  }

  Widget _buildBodyLive() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('laws').snapshots(),
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
          return const Center(child: Text('데이터 없음'));
        }
        return _buildTable(data.docs);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('law데이터 표 (검색지원)')),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isDesktop ? _buildBodyDesktop() : _buildBodyLive(),
          ),
        ],
      ),
    );
  }
}
