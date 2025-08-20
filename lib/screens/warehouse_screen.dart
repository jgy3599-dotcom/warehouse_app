import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'stock_screen.dart';        // 자재현황
import 'stock_add_screen.dart';   // Law데이터 업로드 등
import 'law_list_screen.dart';    // 수정화면
import 'usage_log_screen.dart';   // 사용이력
// 필요에 따라 구매신청/수정화면 등도 import

class WarehouseScreen extends StatefulWidget {
  final bool isAdmin;
  const WarehouseScreen({super.key, this.isAdmin = false});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  Widget _mainContent = const Center(child: Text('기본 화면'));
  int _contentKeySeed = 0; // ✅ 새로고침 시 오른쪽 콘텐츠 강제 재빌드용

  void _selectMenu(Widget screen) {
    setState(() {
      _mainContent = screen;
      _contentKeySeed++; // 다른 메뉴로 바꿀 때도 키 갱신 → 상태 리셋 효과
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // AuthGate가 LoginScreen으로 전환
  }

  void _refreshContent() {
    setState(() {
      _contentKeySeed++; // 키만 바꿔도 오른쪽 뷰가 완전히 재생성되어 FutureBuilder 등이 다시 실행됨
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final title = widget.isAdmin ? '창고 관리 (관리자)' : '창고 관리';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // (선택) 현재 로그인 사용자 표시
          if (user?.email != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContent,
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          // ▶ 왼쪽 메뉴바
          Container(
            width: 250,
            color: Colors.grey[100],
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('메뉴바', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),

                // 자재현황 그룹
                const Text('자재현황', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('현재수량'),
                  onTap: () => _selectMenu(const StockScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('사용이력'),
                  onTap: () => _selectMenu(const UsageLogScreen()),
                ),
                const SizedBox(height: 15),

                // 구매신청 그룹 (예시 자리)
                const Text('구매신청', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('구매신청 이력'),
                  onTap: () {}, // TODO: 화면 연결
                ),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart),
                  title: const Text('구매신청'),
                  onTap: () {}, // TODO: 화면 연결
                ),
                const SizedBox(height: 15),

                // Law데이터 그룹 (관리자만)
                if (widget.isAdmin) ...[
                  const Text('Law데이터', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('law데이터 업로드'),
                    onTap: () => _selectMenu(const StockAddScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: const Text('law데이터 수정'),
                    onTap: () => _selectMenu(const LawListScreen()),
                  ),
                ],
              ],
            ),
          ),

          // ▶ 오른쪽 메인 영역
          Expanded(
            // ✅ 키를 바꿔서 child를 강제로 재생성 → 내부 FutureBuilder/State 초기화
            child: KeyedSubtree(
              key: ValueKey(_contentKeySeed),
              child: _mainContent,
            ),
          ),
        ],
      ),
    );
  }
}
