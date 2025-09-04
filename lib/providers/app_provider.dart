import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/models/note.dart';
import 'package:section_management/models/post.dart';
import 'package:section_management/models/post_doc.dart';
import 'package:section_management/models/state.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/services/database_service.dart';
import 'package:section_management/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  List<Force> _forces = [];
  List<Unit> _units = [];
  List<State> _states = [];
  int _driverCount = 2;

  int get driverCount => _driverCount;

  Future<void> open() async => DatabaseService.instance.open();

  Future<void> restart() async {
    _forces.clear();
    await open();
    await _init();
    notifyListeners();
  }

  void close() => DatabaseService.instance.close();

  AppProvider() {
    _init().ignore();
  }

  Future<void> setDriverCount(int count) async {
    _driverCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('driverCount', count);
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
    final prefs = await SharedPreferences.getInstance();
    _driverCount = prefs.getInt('driverCount') ?? 2;
  }

  Future<List<Force>> filterForces({
    String? searchQuery,
    int? unitId,
    bool? canArmed,
    int? endDate,
    int? leaveDate,
    LeaveType? leaveType,
    int limit = 20,
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
    if (offset == 0) {
      _forces = forces;
    } else {
      _forces.addAll(forces);
    }
    return forces;
  }

  List<Force> get forces => _forces;

  Force? getForceById(int id) {
    return DatabaseService.instance.getForceById(id);
  }

  void addForce(Force forceData) {
    final id = DatabaseService.instance.addForce(forceData);
    forceData.id = id;
    _forces.add(forceData);
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
      endDate: newData.endDate,
      createdDate: oldForce.createdDate,
      canArmed: newData.canArmed,
      unitId: newData.unitId,
      daysOff: newData.daysOff,
      unitName: newData.unitName,
      phoneNo: newData.phoneNo,
      stateType: newData.stateType,
    );
    final changes = Force.compareForces(_units, oldForce, updatedForce);
    if (changes.isNotEmpty) {
      DatabaseService.instance.updateForce(oldForce.id!, updatedForce);
      _forces[_forces.indexWhere((s) => s.id == oldForce.id!)] = updatedForce;
      addNote(oldForce.id!, 'تغییرات نیرو: $changes');
      notifyListeners();
    }
  }

  void deleteForce(int id) {
    DatabaseService.instance.deleteForce(id);
    _forces.removeWhere((force) => force.id == id);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getForcesStatus(
      int date, List<int> unitIds) async {
    final unitForces =
        await DatabaseService.instance.getForcesByUnitIds(unitIds);
    final leaves =
        await DatabaseService.instance.getLeavesByDateAndUnits(date, unitIds);
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
    final presentForces = unitForces.where((s) {
      return !leaves.any((l) => l.forceId == s.id);
      // final forceLeaves = leaves.where((l) => l.forceId == s.id);
      // return !forceLeaves.any((l) => l.fromDate <= date && (l.toDate == null || l.toDate! >= date));
    }).toList();
    return {
      'totalForces': DatabaseService.instance.getCountForces(),
      'unitForces': unitForces,
      'presentForces': presentForces,
      'leaveForces': leaveForces,
      'sickForces': sickForces,
      'absentForces': absentForces,
      'detainedForces': detainedForces,
      'leaves': leaves,
    };
  }

  Future<List<Force>> getPresentForces({
    required int date,
    List<int>? unitIds,
    int limit = 313,
    int offset = 0,
    bool update = false,
  }) async {
    final forces = await DatabaseService.instance.getPresentForces(
      date: date,
      unitIds: unitIds,
      limit: limit,
      offset: offset,
    );
    if (update) {
      if (offset == 0) {
        _forces = forces;
      } else {
        _forces.addAll(forces);
      }
    }
    return forces;
  }

  Future<int> getTotalPresentForces(int date) async {
    return await DatabaseService.instance.getTotalPresentForces(date);
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

  void addNote(int forceId, String note) {
    DatabaseService.instance.addNote(forceId, note);
    notifyListeners();
  }

  Future<List<Note>> getNotesByForceId(int forceId) {
    return DatabaseService.instance.getNotesByForceId(forceId);
  }

  void addUnit(String name) {
    final id = DatabaseService.instance.addUnit(name);
    _units.add(Unit(name: name, id: id));
    notifyListeners();
  }

  void updateUnit(int id, String name) {
    DatabaseService.instance.updateUnit(id, name);
    _units[_units.indexWhere((u) => u.id == id)] = Unit(id: id, name: name);
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

  void updateState(int id, State stateData) {
    DatabaseService.instance.updateState(id, stateData);
    _states[_states.indexWhere((s) => s.id == id)] = State(
      id: id,
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
      DatabaseService.instance.savePost(post);
    }
    DatabaseService.instance.savePostsDoc(postsDoc, dateTs);
    notifyListeners();
  }

  List<Post> getPostsForDate(int dateTs) {
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

  void deletePosts(int dateTs) {
    DatabaseService.instance.deletePosts(dateTs);
  }

  int getLastPostNo(int forceId, StateType stateType, int dateTs) {
    return DatabaseService.instance.getLastPostNo(forceId, stateType, dateTs);
  }

  int? getLastPostDate(int forceId, int dateTs) {
    return DatabaseService.instance.getLastPostDate(forceId, dateTs);
  }

  Future<Map<String, dynamic>> generateProposal(int currentTs) async {
    List<Post> posts = [];
    List<PostDoc> postsDoc = [];
    List<Force> availableForces = await getPresentForces(date: currentTs);
    availableForces = availableForces.where((f) {
      if (f.daysOff == 0) return false;
      final lastPostDate = getLastPostDate(f.id!, currentTs);
      if (lastPostDate != null) {
        int daysSince = (currentTs - lastPostDate) ~/ 86400;
        if (daysSince <= f.daysOff) {
          return false;
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
    availableForces.sort((a, b) => DatabaseService.instance
        .getPostsCountByForceId(a.id!)
        .compareTo(DatabaseService.instance.getPostsCountByForceId(b.id!)));
    List<Map<String, int>> emptyPosts = [];
    for (var state in states.where((s) => s.isActive)) {
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
      candidates.sort((a, b) => a.lastPostNo.compareTo(b.lastPostNo));
      final forcesId = <int>[];
      head:
      for (int i = 0, j = _getMaxPosts(state.stateType); i < j; i++) {
        final post = Post(
          id: null,
          stateId: state.id!,
          postNo: i + 1,
          postDate: currentTs,
          stateName: state.name,
          stateType: state.stateType,
          forceId: 0,
        );
        if (!candidates.isEmpty) {
          for (int j = 0, k = candidates.length; j < k; j++) {
            var candidate = candidates[j];
            if (candidate.lastPostNo == 0 ||
                candidate.lastPostNo == 3 && i == 0 ||
                candidate.lastPostNo == i) {
              availableForces.remove(candidates.removeAt(j));
              forcesId.add(candidate.id!);
              posts.add(post..forceId = candidate.id!);
              continue head;
            }
          }
        }
        emptyPosts.add({
          'forcesIdIndex': forcesId.length,
          'postsDocIndex': postsDoc.length,
          'postsIndex': posts.length,
        });
        forcesId.add(0);
        posts.add(post);
      }
      postsDoc.add(PostDoc(
        stateName: state.name,
        stateType: state.stateType,
        forcesId: forcesId,
        stateId: state.id!,
      ));
    }
    var countOfWarning = 0;
    for (int i = 0, j = min(availableForces.length, emptyPosts.length);
        i < j;
        i++) {
      countOfWarning++;
      final empty = emptyPosts[i];
      posts[empty['postsIndex']!].forceId = availableForces[i].id!;
      postsDoc[empty['postsDocIndex']!].forcesId[empty['forcesIdIndex']!] =
          availableForces[i].id!;
      _validateAssignments(posts[empty['postsIndex']!], {}, currentTs);
    }
    return {
      'posts': posts,
      'postsDoc': postsDoc,
      'countOfWarning': countOfWarning
    };
  }

  int validateAssignments(List<Post> posts, int dateTs) {
    Map<int, int> forceAssignments = {};
    int countOfWarning = 0;
    for (var post in posts) {
      if (_validateAssignments(post, forceAssignments, dateTs))
        countOfWarning++;
    }
    return countOfWarning;
  }

  bool _validateAssignments(
      Post post, Map<int, int> forceAssignments, int dateTs) {
    post.warnings ??= [];
    post.hasError = false;
    if (post.forceId == 0) return false;
    Force? force = getForceById(post.forceId);
    State? state = getStateById(post.stateId);
    if (force == null || state == null) return false;
    final warnings = post.warnings!;
    if (warnings.isNotEmpty) warnings.clear();
    forceAssignments.update(post.forceId, (value) => value + 1,
        ifAbsent: () => 1);
    if (forceAssignments[post.forceId]! > 1) {
      warnings.add('بیش از یک بار تخصیص داده شده است.');
    }
    int lastPostNo = getLastPostNo(post.forceId, state.stateType, dateTs);
    int expectedPostNo = (lastPostNo % _getMaxPosts(state.stateType)) + 1;
    if (lastPostNo != 0 && post.postNo != expectedPostNo) {
      warnings.add('باید در پست ${expectedPostNo} باشد.');
    }
    if (force.daysOff == 0) {
      warnings.add('معاف از پست است.');
    } else {
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

  int _getMaxPosts(StateType stateType) {
    switch (stateType) {
      case StateType.post:
        return 3;
      case StateType.senior_post:
        return 2;
      case StateType.driver:
        return driverCount;
      default:
        return 0;
    }
  }
}
