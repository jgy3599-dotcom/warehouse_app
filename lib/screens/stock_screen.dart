import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_release_dialog.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    if (_searchText.isEmpty) return true;
    final q = _searchText.toLowerCase();
    bool has(String key) => (item[key]?.toString().toLowerCase().contains(q) ?? false);

    return has('대분류') ||
        has('구분') ||
        has('규격') ||
        has('자재이름') ||
        has('설명') ||
        has('제조사') ||
        has('발주코드') ||
        has('상태');
  }

  // ✅ 윈도우 안정화를 위해: 실시간 스트림 대신 1회 조회
  Future<List<Map<String, dynamic>>> _fetchLaws() async {
    final snap = await FirebaseFirestore.instance
        .collection('laws')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? {},
      toFirestore: (data, _) => data,
    )
        .get();

    return snap.docs
        .map((d) => {
      'id': d.id,
      'data': d.data(), // 이미 Map<String, dynamic>
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('현재수량'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // FutureBuilder 다시 실행
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '검색 (대분류/구분/규격/자재이름/제조사/상태 등)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchText = '';
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchText = v),
            ),
          ),

          // ▼ 표 (FutureBuilder로 1회 조회)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLaws(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('오류: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('데이터 없음'));
                }

                final entries = snapshot.data!;
                final filtered = entries
                    .where((e) => _matchesSearch(e['data'] as Map<String, dynamic>))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('검색 결과 없음'));
                }

                // 가로+세로 동시 스크롤 안정 패턴
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // 가로 스크롤
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,  // 세로 스크롤
                              primary: false, // Column/Expanded 중첩 시 필수
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('대분류')),
                                  DataColumn(label: Text('구분')),
                                  DataColumn(label: Text('규격')),
                                  DataColumn(label: Text('자재이름')),
                                  DataColumn(label: Text('설명')),
                                  DataColumn(label: Text('제조사')),
                                  DataColumn(label: Text('수량')),
                                  DataColumn(label: Text('발주코드')),
                                  DataColumn(label: Text('출고')),
                                ],
                                rows: filtered.map((e) {
                                  final id = e['id'] as String;
                                  final item = e['data'] as Map<String, dynamic>;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item['대분류']?.toString() ?? '')),
                                      DataCell(Text(item['구분']?.toString() ?? '')),
                                      DataCell(Text(item['규격']?.toString() ?? '')),
                                      DataCell(Text(item['자재이름']?.toString() ?? '')),
                                      DataCell(Text(item['설명']?.toString() ?? '')),
                                      DataCell(Text(item['제조사']?.toString() ?? '')),
                                      DataCell(Text(item['수량']?.toString() ?? '')),
                                      DataCell(Text(item['발주코드']?.toString() ?? '')),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => StockReleaseDialog(
                                                docId: id,
                                                item: item,
                                              ),
                                            );
                                          },
                                          child: const Text('출고'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
