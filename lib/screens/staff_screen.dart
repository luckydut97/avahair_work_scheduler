import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/shift.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/staff_card.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Theme.of(context).colorScheme.primary,
          child: SafeArea(
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: AppStrings.designer),
                Tab(text: AppStrings.intern),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 디자이너 탭
          _DesignerTab(),
          // 인턴 탭
          _InternTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showDesignerDialog(context);
          } else {
            _showInternDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // 디자이너 추가/수정 다이얼로그
  void _showDesignerDialog(BuildContext context, [Designer? designer]) {
    final nameController = TextEditingController(text: designer?.name ?? '');
    final isEdit = designer != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '디자이너 수정' : '디자이너 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            // 추가 필드 (순번, 휴무일 등)는 여기에 구현
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final designerProvider = Provider.of<DesignerProvider>(context, listen: false);
              final storageService = Provider.of<StorageService>(context, listen: false);

              if (isEdit) {
                final updatedDesigner = designer!.copyWith(name: name);
                designerProvider.updateDesigner(updatedDesigner);
              } else {
                // 순번은 0으로 설정 (의미 없는 값)
                final newDesigner = Designer(
                  id: IDGenerator.generate(),
                  name: name,
                  daysOff: [],
                  turnOrder: 0, // 스케줄 생성 시 재배정됨
                );
                designerProvider.addDesigner(newDesigner);
              }

              // 변경사항 저장
              storageService.saveDesigners(designerProvider.designers);

              Navigator.pop(context);
            },
            child: Text(isEdit ? AppStrings.edit : AppStrings.save),
          ),
        ],
      ),
    );
  }

  // 인턴 추가/수정 다이얼로그
  void _showInternDialog(BuildContext context, [Intern? intern]) {
    final nameController = TextEditingController(text: intern?.name ?? '');
    final isEdit = intern != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '인턴 수정' : '인턴 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            // 추가 필드 (휴무일 등)는 여기에 구현
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final internProvider = Provider.of<InternProvider>(context, listen: false);
              final storageService = Provider.of<StorageService>(context, listen: false);

              if (isEdit) {
                final updatedIntern = intern!.copyWith(name: name);
                internProvider.updateIntern(updatedIntern);
              } else {
                final newIntern = Intern(
                  id: IDGenerator.generate(),
                  name: name,
                  daysOff: [],
                  monthlyShifts: {},
                );
                internProvider.addIntern(newIntern);
              }

              // 변경사항 저장
              storageService.saveInterns(internProvider.interns);

              Navigator.pop(context);
            },
            child: Text(isEdit ? AppStrings.edit : AppStrings.save),
          ),
        ],
      ),
    );
  }
}

// 디자이너 탭 위젯
class _DesignerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DesignerProvider>(
      builder: (context, designerProvider, child) {
        final designers = designerProvider.designers;

        if (designers.isEmpty) {
          return const Center(
            child: Text(AppStrings.noStaff),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: designers.length,
          itemBuilder: (context, index) {
            final designer = designers[index];
            return DesignerCard(
              designer: designer,
              onEdit: () => _editDesigner(context, designer),
              onDelete: () => _deleteDesigner(context, designer),
              onDayOffChange: (dayOff) => _updateDesignerDayOff(context, designer, dayOff),
            );
          },
        );
      },
    );
  }

  // 디자이너 편집
  void _editDesigner(BuildContext context, Designer designer) {
    final screenState = context.findAncestorStateOfType<_StaffScreenState>();
    if (screenState != null) {
      screenState._showDesignerDialog(context, designer);
    }
  }

  // 디자이너 삭제
  void _deleteDesigner(BuildContext context, Designer designer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자이너 삭제'),
        content: Text('${designer.name}님을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final designerProvider = Provider.of<DesignerProvider>(context, listen: false);
              final storageService = Provider.of<StorageService>(context, listen: false);

              designerProvider.removeDesigner(designer.id);
              storageService.saveDesigners(designerProvider.designers);

              Navigator.pop(context);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  // 디자이너 휴무일 업데이트
  void _updateDesignerDayOff(BuildContext context, Designer designer, DateTime dayOff) {
    final designerProvider = Provider.of<DesignerProvider>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final daysOff = List<DateTime>.from(designer.daysOff);
    final isDayOffExists = daysOff.any((d) => DateHelper.isSameDay(d, dayOff));

    if (isDayOffExists) {
      daysOff.removeWhere((d) => DateHelper.isSameDay(d, dayOff));
    } else {
      daysOff.add(dayOff);
    }

    final updatedDesigner = designer.copyWith(daysOff: daysOff);
    designerProvider.updateDesigner(updatedDesigner);
    storageService.saveDesigners(designerProvider.designers);
  }
}

// 인턴 탭 위젯
class _InternTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InternProvider>(
      builder: (context, internProvider, child) {
        final interns = internProvider.interns;

        if (interns.isEmpty) {
          return const Center(
            child: Text(AppStrings.noStaff),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interns.length,
          itemBuilder: (context, index) {
            final intern = interns[index];
            return InternCard(
              intern: intern,
              onEdit: () => _editIntern(context, intern),
              onDelete: () => _deleteIntern(context, intern),
              onDayOffChange: (dayOff) => _updateInternDayOff(context, intern, dayOff),
            );
          },
        );
      },
    );
  }

  // 인턴 편집
  void _editIntern(BuildContext context, Intern intern) {
    final screenState = context.findAncestorStateOfType<_StaffScreenState>();
    if (screenState != null) {
      screenState._showInternDialog(context, intern);
    }
  }

  // 인턴 삭제
  void _deleteIntern(BuildContext context, Intern intern) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인턴 삭제'),
        content: Text('${intern.name}님을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final internProvider = Provider.of<InternProvider>(context, listen: false);
              final storageService = Provider.of<StorageService>(context, listen: false);

              internProvider.removeIntern(intern.id);
              storageService.saveInterns(internProvider.interns);

              Navigator.pop(context);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  // 인턴 휴무일 업데이트
  void _updateInternDayOff(BuildContext context, Intern intern, DateTime dayOff) {
    final internProvider = Provider.of<InternProvider>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final daysOff = List<DateTime>.from(intern.daysOff);
    final isDayOffExists = daysOff.any((d) => DateHelper.isSameDay(d, dayOff));

    if (isDayOffExists) {
      daysOff.removeWhere((d) => DateHelper.isSameDay(d, dayOff));
    } else {
      daysOff.add(dayOff);
    }

    final updatedIntern = intern.copyWith(daysOff: daysOff);
    internProvider.updateIntern(updatedIntern);
    storageService.saveInterns(internProvider.interns);
  }
}