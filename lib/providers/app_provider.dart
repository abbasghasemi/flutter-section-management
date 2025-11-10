import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/models/note.dart';
import 'package:section_management/models/post.dart';
import 'package:section_management/models/post_doc.dart';
import 'package:section_management/models/state.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/services/database_service.dart';
import 'package:section_management/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  List<Unit> _units = [];
  List<State> _states = [];
  int _driverCount = 2;

  int get driverCount => _driverCount;
  late SharedPreferences _prefs;
  late File _checkList;

  Future<void> open() async {
    await DatabaseService.instance.open();
    SharedPreferences.setPrefix("");
    _checkList = File(join(
        await DatabaseService.instance.getDatabasesPath(), 'checklist.v1'));
    _prefs = await SharedPreferences.getInstance();
    AppThemeProvider.light = isLightTheme();
    await _init();
  }

  Future<void> restart() async {
    await DatabaseService.instance.open();
    await _init();
    notifyListeners();
  }

  void close() => DatabaseService.instance.close();

  Future<void> setDriverCount(int count) async {
    _driverCount = count;
    await _prefs.setInt('driverCount', count);
    notifyListeners();
  }

  void _sortStates() {
    _states.sort((a, b) {
      final c = a.stateType.index.compareTo(b.stateType.index);
      if (c != 0) {
        return c;
      }
      return a.unitId.compareTo(b.unitId);
    });
  }

  Future<void> _init() async {
    _units = await DatabaseService.instance.getAllUnits();
    _states = await DatabaseService.instance.getAllStates();
    _sortStates();
    _driverCount = _prefs.getInt('driverCount') ?? 2;
  }

  Future<List<Force>> filterForces({
    String? searchQuery,
    int? unitId,
    bool? canArmed,
    int? endDate,
    int? leaveDate,
    LeaveType? leaveType,
    int limit = 1000,
    int offset = 0,
  }) async {
    final forces = await DatabaseService.instance.filterForces(
      searchQuery: searchQuery,
      unitId: unitId,
      canArmed: canArmed,
      endDate: endDate,
      leaveDate: leaveDate,
      leaveType: leaveType,
      limit: limit,
      offset: offset,
    );
    return forces;
  }

  Force? getForceById(int id) {
    return DatabaseService.instance.getForceById(id);
  }

  Future<List<Force>> getForcesByUnitIds(
      List<int> unitIds, bool inUnitIds, int? presenceTs) async {
    return DatabaseService.instance
        .getForcesByUnitIds(unitIds, inUnitIds, presenceTs);
  }

  void addForce(Force forceData) {
    final id = DatabaseService.instance.addForce(forceData);
    forceData.id = id;
    notifyListeners();
  }

  void updateForce(Force oldForce, Force newData) {
    final updatedForce = Force(
      id: oldForce.id,
      codeMeli: newData.codeMeli,
      firstName: newData.firstName,
      lastName: newData.lastName,
      fatherName: newData.fatherName,
      isNative: newData.isNative,
      isMarried: newData.isMarried,
      endDate: newData.endDate,
      createdDate: newData.createdDate,
      deletedDate: null,
      canArmed: newData.canArmed,
      unitId: newData.unitId,
      unitName: _units.firstWhere((e) => e.id == newData.unitId).name,
      daysOff: newData.daysOff,
      workdays: newData.workdays,
      phoneNo: newData.phoneNo,
      stateType: newData.stateType,
      codeId: newData.codeId,
    );
    final changes = Force.compareForces(_units, oldForce, updatedForce);
    if (changes != null) {
      DatabaseService.instance.updateForce(oldForce.id!, updatedForce);
      if (changes.isNotEmpty) {
        addNote(oldForce.id!, 'تغییرات نیرو: $changes', 0);
      }
      notifyListeners();
    }
  }

  void deleteForce(int id, int deleteTs) {
    DatabaseService.instance.deleteForce(id, deleteTs);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getForcesStatus(
      int date, List<int> unitIds, bool inUnitIds) async {
    final unitForces = await DatabaseService.instance
        .getForcesByUnitIds(unitIds, inUnitIds, null);
    final leaves = await DatabaseService.instance
        .getLeavesByDateAndUnits(date, unitIds, inUnitIds);
    final oldLeaves = (await DatabaseService.instance.getLeavesByDateAndUnits(
            date - reportDayCount() * 24 * 60 * 60, unitIds, inUnitIds))
        .where((l) =>
            l.leaveType != LeaveType.hourly &&
            l.toDate != null &&
            l.toDate! < date)
        .toList();
    final leaveForces = leaves
        .where((l) => l.leaveType == LeaveType.presence)
        .map((l) => unitForces.firstWhere((s) => s.id == l.forceId))
        .toList();
    final sickForces = leaves
        .where((l) => l.leaveType == LeaveType.sick)
        .map((l) => unitForces.firstWhere((s) => s.id == l.forceId))
        .toList();
    final absentForces = leaves
        .where((l) => l.leaveType == LeaveType.absent)
        .map((l) => unitForces.firstWhere((s) => s.id == l.forceId))
        .toList();
    final detainedForces = leaves
        .where((l) => l.leaveType == LeaveType.detention)
        .map((l) => unitForces.firstWhere((s) => s.id == l.forceId))
        .toList();
    final missionForces = leaves
        .where((l) => l.leaveType == LeaveType.mission)
        .map((l) => unitForces.firstWhere((s) => s.id == l.forceId))
        .toList();
    final presentForces = unitForces.where((s) {
      return !leaves.any((l) => l.forceId == s.id);
    }).toList();
    return {
      'totalForces': DatabaseService.instance.getCountForces(),
      'unitForces': unitForces,
      'presentForces': presentForces,
      'leaveForces': leaveForces,
      'oldLeaves': oldLeaves,
      'sickForces': sickForces,
      'absentForces': absentForces,
      'detainedForces': detainedForces,
      'missionForces': missionForces,
      'leaves': leaves,
    };
  }

  Future<List<Force>> getPresentForces({
    required int date,
    List<int>? unitIds,
    bool? isMarried,
    int limit = 1000,
    int offset = 0,
  }) async {
    return await DatabaseService.instance.getPresentForces(
      date: date,
      unitIds: unitIds,
      isMarried: isMarried,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Leave>> getLeavesByForceId(int forceId) async {
    return DatabaseService.instance.getLeavesByForceId(forceId);
  }

  Leave? getLastLeaveByDate(int forceId, int dateTs) {
    return DatabaseService.instance.getLastLeaveByDate(forceId, dateTs);
  }

  void addLeave(Leave leave) {
    DatabaseService.instance.addLeave(leave);
    notifyListeners();
  }

  List<Unit> get units => _units;

  void updateLeave(int id, Leave newLeave) {
    DatabaseService.instance.updateLeave(id, newLeave);
    notifyListeners();
  }

  void deleteLeave(int id) {
    DatabaseService.instance.deleteLeave(id);
    notifyListeners();
  }

  void addNote(int forceId, String note, int priority) {
    DatabaseService.instance.addNote(forceId, note, priority);
    notifyListeners();
  }

  Future<List<Note>> getNotesByForceId(int forceId) {
    return DatabaseService.instance.getNotesByForceId(forceId);
  }

  void addUnit(String name, int maxUsage, int unitType, String description) {
    final id =
        DatabaseService.instance.addUnit(name, maxUsage, unitType, description);
    _units.add(Unit(
        name: name,
        id: id,
        maxUsage: maxUsage,
        unitType: unitType,
        description: description));
    notifyListeners();
  }

  void updateUnit(Unit unit) {
    DatabaseService.instance.updateUnit(unit);
    notifyListeners();
  }

  bool canDeleteUnit(int id) {
    return DatabaseService.instance.canDeleteUnit(id);
  }

  void deleteUnit(int id) {
    DatabaseService.instance.deleteUnit(id);
    _units.removeWhere((unit) => unit.id == id);
    notifyListeners();
  }

  void addState(State stateData) {
    final id = DatabaseService.instance.addState(stateData);
    _states.add(stateData..id = id);
    _sortStates();
    notifyListeners();
  }

  List<State> get states => _states;

  State? getStateById(int id) {
    try {
      return _states.firstWhere((state) => state.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateState(State stateData) {
    DatabaseService.instance.updateState(stateData);
    _states[_states.indexWhere((s) => s.id == stateData.id)] = State(
      id: stateData.id,
      name: stateData.name,
      isActive: stateData.isActive,
      isArmed: stateData.isArmed,
      stateType: stateData.stateType,
      unitId: stateData.unitId,
    );
    _sortStates();
    notifyListeners();
  }

  bool canDeleteState(int id) {
    return DatabaseService.instance.canDeleteState(id);
  }

  void deleteState(int id) {
    DatabaseService.instance.deleteState(id);
    _states.removeWhere((state) => state.id == id);
    notifyListeners();
  }

  void savePosts(List<PostDoc> postsDoc, List<Post> posts, int dateTs) {
    deletePosts(dateTs);
    for (var post in posts) {
      if (post.forceId == 0) continue;
      post.postDate = dateTs;
      DatabaseService.instance.savePost(post);
    }
    DatabaseService.instance.savePostsDoc(postsDoc, dateTs);
  }

  List<Post> getPostsByDate(int dateTs) {
    return DatabaseService.instance.getPostsByDate(dateTs);
  }

  Future<int> getPostsCountByForceId(int forceId) async {
    return DatabaseService.instance.getPostsCountByForceId(forceId);
  }

  List<PostDoc> getPostsDocByDate(int dateTs) {
    return DatabaseService.instance.getPostsDocByDate(dateTs);
  }

  Future<List<Post>> getPostsByForceId(int forceId) async {
    return DatabaseService.instance.getPostsByForceId(forceId);
  }

  Future<List<Post>> getRangePostsByTs(int startTs, int endTs) async {
    return DatabaseService.instance.getRangePostsByTs(startTs, endTs);
  }

  void deletePosts(int dateTs) {
    DatabaseService.instance.deletePosts(dateTs);
  }

  int getLastPostNo(int forceId, StateType stateType, int dateTs) {
    return DatabaseService.instance.getLastPostNo(forceId, stateType, dateTs);
  }

  int? getLastPostDate(int forceId, int dateTs) {
    return DatabaseService.instance.getLastPostDate(forceId, dateTs);
  }

  Future<int> getLastDateLeave(int forceId) {
    return DatabaseService.instance.getLastDateLeave(forceId);
  }

  Future<Post?> getLastPost(int forceId) {
    return DatabaseService.instance.getLastPost(forceId);
  }

  Future<Map<String, int>> getForceInfo(int forceId) async {
    return {
      "lastDateLeave": await getLastDateLeave(forceId),
      "postsCount": await getPostsCountByForceId(forceId)
    };
  }

  Map<String, dynamic> rawPosts(int currentTs, Iterable<State> states) {
    List<Post> posts = [];
    List<PostDoc> postsDoc = [];
    for (var state in states) {
      final forcesId = <int>[];
      for (int i = 0, j = getMaxPosts(state.stateType); i < j; i++) {
        final post = Post(
          id: null,
          stateId: state.id!,
          postNo: i + 1,
          postDate: currentTs,
          stateName: state.name,
          stateType: state.stateType,
          forceId: 0,
          postStatus: PostStatus.ok,
          postDescription: '',
        );
        forcesId.add(0);
        posts.add(post);
      }
      postsDoc.add(PostDoc(
        stateName: state.name,
        stateType: state.stateType,
        forcesId: forcesId,
        isArmed: state.isArmed,
        stateId: state.id!,
      ));
    }
    return {'posts': posts, 'postsDoc': postsDoc, 'countOfWarning': 0};
  }

  Future<Map<String, dynamic>> generateProposal(
      int currentTs, Iterable<State> states) async {
    final _indexOfWeek = indexOfWeek(currentTs);
    List<Post> posts = [];
    List<PostDoc> postsDoc = [];
    List<Force> availableForces = await getPresentForces(
        date: currentTs, isMarried: useMarried() ? null : false);
    availableForces = availableForces.where((f) {
      final okState = f.stateType == StateType.post ||
          f.stateType == StateType.senior_post ||
          f.stateType == StateType.driver;
      if (f.daysOff == -1 ||
          !(f.workdays & (1 << _indexOfWeek) != 0) ||
          !okState) return false;
      if (f.daysOff != 0) {
        final lastPostDate = getLastPostDate(f.id!, currentTs);
        if (lastPostDate != null) {
          int daysSince = (currentTs - lastPostDate) ~/ 86400;
          if (daysSince <= f.daysOff) {
            return false;
          }
        }
      }
      final lastLeaveDate = getLastLeaveByDate(f.id!, currentTs);
      if (lastLeaveDate != null) {
        final index = lastLeaveDate.details
            .lastIndexWhere((i) => i.title.name == DetentionType.days_off.name);
        if (index != -1) {
          final endDate =
              lastLeaveDate.toDate! + lastLeaveDate.details[index].days * 86400;
          if (currentTs <= endDate) {
            return false;
          }
        }
      }
      return true;
    }).toList();
    final filterUnitPriority = allowFilterUnitPriority();
    availableForces.sort((a, b) {
      if (filterUnitPriority) {
        bool aIsPriorityUnit = a.unitId == 1 || a.unitId == 2;
        bool bIsPriorityUnit = b.unitId == 1 || b.unitId == 2;
        if (aIsPriorityUnit && !bIsPriorityUnit) return -1;
        if (!aIsPriorityUnit && bIsPriorityUnit) return 1;
      }
      return DatabaseService.instance
          .getPostsCountByForceId(a.id!)
          .compareTo(DatabaseService.instance.getPostsCountByForceId(b.id!));
    });
    if (allowFilterMaxUsage()) {
      List<Force> filteredForces = [];
      Map<int, int> unitCounts = {};
      for (var force in availableForces) {
        final unit = _units.firstWhere((u) => u.id == force.unitId);
        final currentCount = unitCounts[force.unitId] ?? 0;
        if (unit.maxUsage < 0 || currentCount < unit.maxUsage) {
          filteredForces.add(force);
          unitCounts[force.unitId] = currentCount + 1;
        }
      }
      availableForces = filteredForces;
    }
    List<Map<String, int>> emptyPosts = [];
    for (var state in states) {
      List<Force> candidates = availableForces.where((f) {
        bool unitMatch = f.unitId == state.unitId ||
            f.isNative ||
            (f.unitId != 1 && f.unitId != 2);
        bool armedMatch = !state.isArmed || f.canArmed;
        final match = state.stateType == f.stateType && unitMatch && armedMatch;
        if (match) {
          f.lastPostNo = getLastPostNo(f.id!, state.stateType, currentTs);
        }
        return match;
      }).toList();

      final maxPosts = getMaxPosts(state.stateType);
      Map<int, int> postToForce = {};
      Set<int> assignedPostNos = {};

      for (var candidate in candidates) {
        int? nextPost;
        if (candidate.lastPostNo == 0) {
          for (int pn = 1; pn <= maxPosts; pn++) {
            if (!assignedPostNos.contains(pn)) {
              nextPost = pn;
              break;
            }
          }
        } else {
          int preferred = ((candidate.lastPostNo - 1 + 1) % maxPosts) + 1;
          if (!assignedPostNos.contains(preferred)) {
            nextPost = preferred;
          } else {
            bool found = false;
            for (int offset = 1; offset < maxPosts; offset++) {
              int alt = ((candidate.lastPostNo - 1 + offset) % maxPosts) + 1;
              if (!assignedPostNos.contains(alt)) {
                nextPost = alt;
                found = true;
                break;
              }
            }
            if (!found) {
              for (int pn = 1; pn <= maxPosts; pn++) {
                if (!assignedPostNos.contains(pn)) {
                  nextPost = pn;
                  break;
                }
              }
            }
          }
        }

        if (nextPost != null) {
          assignedPostNos.add(nextPost);
          postToForce[nextPost] = candidate.id!;
          availableForces.removeWhere((f) => f.id == candidate.id);
        }
      }

      final forcesId = <int>[];
      for (int i = 1; i <= maxPosts; i++) {
        final forceId = postToForce[i] ?? 0;
        forcesId.add(forceId);

        final post = Post(
          id: null,
          stateId: state.id!,
          postNo: i,
          postDate: currentTs,
          stateName: state.name,
          stateType: state.stateType,
          forceId: forceId,
          postStatus: PostStatus.ok,
          postDescription: '',
        );

        posts.add(post);

        if (forceId == 0) {
          emptyPosts.add({
            'forcesIdIndex': forcesId.length - 1,
            'postsDocIndex': postsDoc.length,
            'postsIndex': posts.length - 1,
          });
        }
      }

      postsDoc.add(PostDoc(
        stateName: state.name,
        stateType: state.stateType,
        forcesId: forcesId,
        isArmed: state.isArmed,
        stateId: state.id!,
      ));
    }
    for (int i = 0, j = min(availableForces.length, emptyPosts.length);
        i < j;
        i++) {
      final empty = emptyPosts[i];
      posts[empty['postsIndex']!].forceId = availableForces[i].id!;
      postsDoc[empty['postsDocIndex']!].forcesId[empty['forcesIdIndex']!] =
          availableForces[i].id!;
    }
    final countOfWarning = validateAssignments(posts, currentTs);
    return {
      'posts': posts,
      'postsDoc': postsDoc,
      'countOfWarning': countOfWarning
    };
  }

  int validateAssignments(List<Post> posts, int dateTs) {
    Map<int, int> forceAssignments = {};
    Map<int, int> unitAssignments = {};
    int countOfWarning = 0;
    if (dateTimestamp() <= dateTs) {
      for (var post in posts) {
        bool plusplus = true;
        if (allowFilterMaxUsage()) {
          Force? force = getForceById(post.forceId);
          if (force != null) {
            unitAssignments.update(force.unitId, (value) => value + 1,
                ifAbsent: () => 1);
            final unit = _units.firstWhere((u) => u.id == force.unitId);
            if (unit.maxUsage >= 0 &&
                unitAssignments[force.unitId]! > unit.maxUsage) {
              post.warnings ??= [];
              if (post.warnings!.isNotEmpty) post.warnings!.clear();
              post.warnings!.add('بیش از حداکثر استفاده واحد ${unit.name}');
              countOfWarning++;
              plusplus = false;
            }
          }
        }
        if (_validateAssignments(post, forceAssignments, dateTs, plusplus) &&
            plusplus) countOfWarning++;
      }
    }
    return countOfWarning;
  }

  bool _validateAssignments(
    Post post,
    Map<int, int> forceAssignments,
    int dateTs,
    bool plusplus,
  ) {
    final _indexOfWeek = indexOfWeek(dateTs);
    post.warnings ??= [];
    post.hasError = !plusplus;
    if (post.forceId == 0) return false;
    Force? force = getForceById(post.forceId);
    State? state = getStateById(post.stateId);
    if (force == null || state == null) return false;
    final warnings = post.warnings!;
    if (plusplus && warnings.isNotEmpty) warnings.clear();
    forceAssignments.update(post.forceId, (value) => value + 1,
        ifAbsent: () => 1);
    if (forceAssignments[post.forceId]! > 1) {
      warnings.add('بیش از یک بار تخصیص داده شده است.');
      post.hasError = true;
    }
    if (!(force.workdays & (1 << _indexOfWeek) != 0)) {
      warnings.add("${nameOfWeek(_indexOfWeek)} روز کاری نیرو نمی باشد.");
      post.hasError = true;
    }
    int lastPostNo = getLastPostNo(post.forceId, state.stateType, dateTs);
    int expectedPostNo = (lastPostNo % getMaxPosts(state.stateType)) + 1;
    if (lastPostNo != 0 && post.postNo != expectedPostNo) {
      warnings.add('باید در پست ${expectedPostNo} باشد.');
    }
    if (force.daysOff == -1) {
      warnings.add('معاف از پست است.');
    } else if (force.daysOff != 0) {
      final lastPostDate = getLastPostDate(post.forceId, dateTs);
      if (lastPostDate != null) {
        int daysSince = (dateTs - lastPostDate) ~/ 86400;
        if (daysSince <= force.daysOff) {
          post.hasError = true;
          warnings.add(
              'آخرین بکارگیری در ${timestampToShamsi(lastPostDate)} و بکارگیری بعدی در ${timestampToShamsi(lastPostDate + (force.daysOff + 1) * 86400)} می باشد.');
        }
      }
      final lastLeaveDate = getLastLeaveByDate(post.forceId, dateTs);
      if (lastLeaveDate != null) {
        final index = lastLeaveDate.details
            .lastIndexWhere((i) => i.title.name == DetentionType.days_off.name);
        if (index != -1) {
          final endDate = lastLeaveDate.toDate! +
              (lastLeaveDate.details[index].days + 1) * 86400;
          if (dateTs < endDate) {
            post.hasError = true;
            warnings
                .add('بکارگیری باید در ${timestampToShamsi(endDate)} می باشد.');
          }
        }
      }
    }
    if (state.isArmed && !force.canArmed) {
      warnings.add('نمی تواند در پست مسلح باشد.');
      post.hasError = true;
    }
    if (state.stateType != force.stateType) {
      warnings.add(
          'با مسئولیت ${force.stateType.fa} در مسئولیت ${state.stateType.fa} قرار گرفته است.');
    }
    bool unitMatch = force.unitId == state.unitId ||
        force.isNative ||
        (force.unitId != 1 && force.unitId != 2);
    if (!unitMatch) {
      warnings.add('تطابق واحد با ${force.unitName} ندارد.');
    }
    return warnings.isNotEmpty;
  }

  int getMaxPosts(StateType stateType) {
    switch (stateType) {
      case StateType.post:
        return postCount();
      case StateType.senior_post:
        return seniorPostCount();
      case StateType.driver:
        return driverCount;
      default:
        return 0;
    }
  }

  List<int> unitsPost() {
    return _units.where((u) => u.unitType != 0).map((u) => u.id!).toList();
  }

  bool isLightTheme() {
    return _prefs.getBool('lightTheme') ?? true;
  }

  Future<void> setThemeStatus(bool light) async {
    await _prefs.setBool('lightTheme', light);
  }

  String getPassword() {
    return _prefs.getString('password') ?? '1234';
  }

  Future<void> setPassword(String newPassword) async {
    await _prefs.setString('password', newPassword);
  }

  double getMultiplierOfTheMonth() {
    return _prefs.getDouble('multiplierOfTheMonth') ?? 3.75;
  }

  Future<void> setMultiplierOfTheMonth(double mul) async {
    await _prefs.setDouble('multiplierOfTheMonth', mul);
  }

  bool allowFilterMaxUsage() {
    return _prefs.getBool('allowFilterMaxUsage') ?? true;
  }

  Future<void> setAllowFilterMaxUsage(bool status) async {
    await _prefs.setBool('allowFilterMaxUsage', status);
  }

  bool allowFilterUnitPriority() {
    return _prefs.getBool('allowFilterUnitPriority') ?? true;
  }

  Future<void> setAllowFilterUnitPriority(bool status) async {
    await _prefs.setBool('allowFilterUnitPriority', status);
  }

  bool showFatherName() {
    return _prefs.getBool('showFatherName') ?? true;
  }

  Future<void> setShowFatherName(bool status) async {
    await _prefs.setBool('showFatherName', status);
  }

  int totalImportDatabase() {
    return _prefs.getInt('totalImportDatabase') ?? 0;
  }

  Future<void> importDatabase() async {
    await _prefs.setInt('totalImportDatabase', totalImportDatabase() + 1);
  }

  bool useMarried() {
    return _prefs.getBool('useMarried') ?? false;
  }

  Future<void> setUseMarried(bool status) async {
    await _prefs.setBool('useMarried', status);
  }

  String checklist() {
    if (!_checkList.existsSync()) {
      return '';
    }
    return _checkList.readAsStringSync();
  }

  Future<void> setChecklist(String text) async {
    _checkList.writeAsString(text, mode: FileMode.writeOnly);
  }

  int postCount() {
    return _prefs.getInt('postCount') ?? 3;
  }

  Future<void> setPostCount(int count) async {
    await _prefs.setInt('postCount', count);
  }

  int seniorPostCount() {
    return _prefs.getInt('seniorPostCount') ?? 2;
  }

  Future<void> setSeniorPostCount(int count) async {
    await _prefs.setInt('seniorPostCount', count);
  }

  String getPostContentText(int index) {
    return _prefs.getString('postContentText$index') ?? '';
  }

  Future<void> setPostContentText(int index, String name) async {
    await _prefs.setString('postContentText$index', name);
  }

  int fontSizeName() {
    return _prefs.getInt('fontSizeName') ?? 17;
  }

  Future<void> setFontSizeName(int size) async {
    await _prefs.setInt('fontSizeName', size);
  }

  int fontSizeTitle() {
    return _prefs.getInt('fontSizeTitle') ?? 17;
  }

  Future<void> setFontSizeTitle(int size) async {
    await _prefs.setInt('fontSizeTitle', size);
  }

  int reportDayCount() {
    return _prefs.getInt('reportDayCount') ?? 7;
  }

  Future<void> setReportDayCount(int count) async {
    await _prefs.setInt('reportDayCount', count);
  }
}
