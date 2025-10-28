import 'dart:convert';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/models/note.dart';
import 'package:section_management/models/post.dart';
import 'package:section_management/models/post_doc.dart';
import 'package:section_management/models/state.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/utility.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  late Database db;

  DatabaseService._();

  Future<String> getDatabasesPath() async =>
      (await getApplicationSupportDirectory()).path;

  Future<Database> open() async {
    final dbPath = join(await getDatabasesPath(), 'sm.db');
    db = sqlite3.open(dbPath);
    await _createDB(db);
    return db;
  }

  void close() => db.dispose();

  Future<void> _createDB(Database db) async {
    db.execute(
        'CREATE TABLE IF NOT EXISTS forces(id INTEGER PRIMARY KEY AUTOINCREMENT, code_meli TEXT UNIQUE NOT NULL, code_id TEXT NOT NULL, first_name TEXT NOT NULL, last_name TEXT NOT NULL, father_name TEXT NOT NULL, is_native INTEGER NOT NULL, is_married INTEGER NOT NULL, end_date INTEGER NOT NULL, created_date INTEGER NOT NULL, can_armed INTEGER NOT NULL, unit_id INTEGER NOT NULL, days_off INTEGER NOT NULL, work_days INTEGER NOT NULL, phone_no INTEGER NOT NULL, state_type TEXT NOT NULL, FOREIGN KEY(unit_id) REFERENCES units(id))');
    db.execute(
        'CREATE TABLE IF NOT EXISTS units(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, max_usage INTEGER NOT NULL, description TEXT NOT NULL)');
    db.execute(
        'CREATE TABLE IF NOT EXISTS states(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, is_active INTEGER NOT NULL, is_armed INTEGER NOT NULL, state_type TEXT NOT NULL, unit_id INTEGER NOT NULL, FOREIGN KEY(unit_id) REFERENCES units(id))');
    db.execute(
        'CREATE TABLE IF NOT EXISTS leaves(id INTEGER PRIMARY KEY AUTOINCREMENT, force_id INTEGER NOT NULL, from_date INTEGER NOT NULL, to_date INTEGER, leave_type TEXT NOT NULL, details TEXT NOT NULL, FOREIGN KEY(force_id) REFERENCES forces(id))');
    db.execute(
        'CREATE TABLE IF NOT EXISTS posts(id INTEGER PRIMARY KEY AUTOINCREMENT, force_id INTEGER NOT NULL, state_id INTEGER NOT NULL, state_name TEXT NOT NULL, state_type TEXT NOT NULL, post_no INTEGER NOT NULL, post_date INTEGER NOT NULL, post_status TEXT NOT NULL, post_description TEXT NOT NULL, FOREIGN KEY(force_id) REFERENCES forces(id), FOREIGN KEY(state_id) REFERENCES states(id))');
    db.execute(
        'CREATE TABLE IF NOT EXISTS posts_doc(id INTEGER PRIMARY KEY AUTOINCREMENT, post_date INTEGER NOT NULL, doc_json TEXT NOT NULL)');
    db.execute(
        'CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY AUTOINCREMENT, force_id INTEGER NOT NULL, note TEXT NOT NULL, note_date INTEGER NOT NULL, priority INTEGER NOT NULL, FOREIGN KEY(force_id) REFERENCES forces(id))');
    db.execute(
        'CREATE TABLE IF NOT EXISTS current_version(id INTEGER PRIMARY KEY AUTOINCREMENT, cv INTEGER NOT NULL)');
    await _createIndexes(db);
    await _prePopulateData(db);
    await _check_version(db);
  }

  Future<void> _createIndexes(Database db) async {
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_forces_unit_id ON forces(unit_id)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_forces_can_armed ON forces(can_armed)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_forces_end_date ON forces(end_date)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_leaves_force_id ON leaves(force_id)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_leaves_from_date ON leaves(from_date)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_leaves_to_date ON leaves(to_date)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_leaves_leave_type ON leaves(leave_type)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_force_id ON posts(force_id)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_post_date ON posts(post_date)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_doc_post_date ON posts_doc(post_date)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_force_id ON notes(force_id)');
  }

  Future<void> _prePopulateData(Database db) async {
    db.execute(
        'INSERT OR IGNORE INTO units(id, name, max_usage, description) VALUES(?, ?, ?, ?)',
        [0, "موقت", -1, '']);
    db.execute(
        'INSERT OR IGNORE INTO units(id, name, max_usage, description) VALUES(?, ?, ?, ?)',
        [1, "واحد 1", -1, '']);
    db.execute(
        'INSERT OR IGNORE INTO units(id, name, max_usage, description) VALUES(?, ?, ?, ?)',
        [2, "واحد 2", -1, '']);
  }

  Future<void> _check_version(Database db) async {
    final results = db.select('SELECT cv FROM current_version');
    if (results.isEmpty) {
      try {
        db.execute(
            "ALTER TABLE forces ADD COLUMN code_id TEXT NOT NULL DEFAULT ''");
        db.execute(
            "ALTER TABLE forces ADD COLUMN work_days INTEGER NOT NULL DEFAULT 127");
        db.execute(
            "ALTER TABLE posts ADD COLUMN post_status TEXT NOT NULL DEFAULT 'ok'");
        db.execute(
            "ALTER TABLE posts ADD COLUMN post_description TEXT NOT NULL DEFAULT ''");
        db.execute(
            "ALTER TABLE units ADD COLUMN description TEXT NOT NULL DEFAULT ''");
        db.execute(
            "ALTER TABLE notes ADD COLUMN priority INTEGER NOT NULL DEFAULT 0");
      } catch (e) {
        //
      }
      db.execute('INSERT INTO current_version(cv) VALUES(?)', [1]);
    } else {
      if (results.first['cv'] == 1) {
        // db.execute("UPDATE current_version SET cv = ?", [2]);
      }
      if (results.first['cv'] != 1) {
        appWindow.close();
      }
    }
  }

  int getCountForces() {
    final results = db.select('SELECT COUNT(*) as total FROM forces');
    return results.first['total'] as int;
  }

  Future<List<Force>> filterForces({
    String? searchQuery,
    int? unitId,
    bool? canArmed,
    int? endDate,
    int? leaveDate,
    LeaveType? leaveType,
    int limit = 313,
    int offset = 0,
  }) async {
    final params = <dynamic>[];
    final conditions = <String>[];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      searchQuery = searchQuery.trim();
      if (int.tryParse(searchQuery) != null) {
        conditions.add('f.code_meli LIKE ?');
        params.add('%$searchQuery%');
      } else {
        final part = searchQuery.split(" ");
        if (part.length > 1) {
          conditions.add('(f.first_name LIKE ? AND f.last_name LIKE ?)');
          params.add('%${part.removeAt(0)}%');
          params.add('%${part.join(' ')}%');
        } else {
          conditions.add('(f.first_name LIKE ? OR f.last_name LIKE ?)');
          params.add('%$searchQuery%');
          params.add('%$searchQuery%');
        }
      }
    }
    if (unitId != null) {
      conditions.add('f.unit_id = ?');
      params.add(unitId);
    }
    if (canArmed != null) {
      conditions.add('f.can_armed = ?');
      params.add(canArmed ? 1 : 0);
    }
    if (endDate != null) {
      conditions.add('f.end_date <= ?');
      params.add(endDate);
    }
    if (leaveDate != null) {
      conditions.add(
          'EXISTS(SELECT 1 FROM leaves l WHERE l.force_id = f.id AND l.from_date <= ? AND(l.to_date IS NULL OR l.to_date >= ?) ${leaveType != null ? 'AND l.leave_type = ?' : ''})');
      params.add(leaveDate);
      params.add(leaveDate);
      if (leaveType != null) {
        params.add(leaveType.name);
      }
    }
    final query =
        'SELECT DISTINCT f.*,u.name as unit_name FROM forces f ${leaveDate != null ? 'LEFT JOIN leaves l ON l.force_id = f.id LEFT JOIN units u ON u.id = f.unit_id' : 'LEFT JOIN units u ON u.id = f.unit_id'} ${conditions.isNotEmpty ? 'WHERE ${conditions.join('AND ')}' : ''} LIMIT ? OFFSET ? ';
    params.add(limit == -1 ? null : limit);
    params.add(offset);
    final results = db.select(query, params);
    return results.map((row) => Force.fromMap(row)).toList();
  }

  Force? getForceById(int id) {
    final results = db.select(
        'SELECT forces.*,units.name as unit_name FROM forces LEFT JOIN units ON units.id = forces.unit_id WHERE forces.id = ?',
        [id]);
    if (results.isEmpty) return null;
    return Force.fromMap(results.first);
  }

  Future<List<Force>> getForcesByUnitIds(
      List<int> unitIds, bool inUnitIds) async {
    final results = db.select(
        'SELECT forces.*,units.name as unit_name FROM forces LEFT JOIN units ON units.id = forces.unit_id WHERE forces.unit_id ${inUnitIds ? '' : 'NOT '}IN(${unitIds.join(',')})');
    return results.map((row) => Force.fromMap(row)).toList();
  }

  int addForce(Force forceData) {
    db.execute(
      'INSERT INTO forces(code_meli, code_id, first_name, last_name, father_name, is_native,is_married, end_date, created_date, can_armed, unit_id, days_off, work_days, phone_no, state_type) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ',
      [
        forceData.codeMeli,
        forceData.codeId,
        forceData.firstName,
        forceData.lastName,
        forceData.fatherName,
        forceData.isNative ? 1 : 0,
        forceData.isMarried ? 1 : 0,
        forceData.endDate,
        forceData.createdDate,
        forceData.canArmed ? 1 : 0,
        forceData.unitId,
        forceData.daysOff,
        forceData.workdays,
        forceData.phoneNo,
        forceData.stateType.name,
      ],
    );
    return db.lastInsertRowId;
  }

  void updateForce(int id, Force forceData) {
    db.execute(
      'UPDATE forces SET code_meli = ?, code_id = ?, first_name = ?, last_name = ?, father_name = ?, is_native = ?, is_married = ?, end_date = ?, can_armed = ?, unit_id = ?, days_off = ?, work_days = ?, phone_no = ?, state_type = ? WHERE id = ? ',
      [
        forceData.codeMeli,
        forceData.codeId,
        forceData.firstName,
        forceData.lastName,
        forceData.fatherName,
        forceData.isNative ? 1 : 0,
        forceData.isMarried ? 1 : 0,
        forceData.endDate,
        forceData.canArmed ? 1 : 0,
        forceData.unitId,
        forceData.daysOff,
        forceData.workdays,
        forceData.phoneNo,
        forceData.stateType.name,
        id,
      ],
    );
  }

  void deleteForce(int id) {
    db.execute('DELETE FROM leaves WHERE force_id = ?', [id]);
    db.execute('DELETE FROM posts WHERE force_id = ?', [id]);
    db.execute('DELETE FROM notes WHERE force_id = ?', [id]);
    db.execute('DELETE FROM forces WHERE id = ?', [id]);
  }

  Future<List<Force>> getPresentForces({
    required int date,
    List<int>? unitIds,
    bool? isMarried,
    int limit = 313,
    int offset = 0,
  }) async {
    final married = isMarried != null
        ? 'f.is_married = ${isMarried ? 'true' : 'false'} AND'
        : '';
    final params = <dynamic>[LeaveType.hourly.name, date, date];
    final query = unitIds != null
        ? 'SELECT DISTINCT f.*,u.name as unit_name FROM forces f LEFT JOIN units u ON u.id = f.unit_id WHERE $married f.unit_id IN(${unitIds.join(',')}) AND NOT EXISTS(SELECT 1 FROM leaves l WHERE l.force_id = f.id AND l.leave_type != ? AND l.from_date <= ? AND(l.to_date IS NULL OR l.to_date >= ?)) LIMIT ? OFFSET ? '
        : 'SELECT DISTINCT f.*,u.name as unit_name FROM forces f LEFT JOIN units u ON u.id = f.unit_id WHERE $married NOT EXISTS(SELECT 1 FROM leaves l WHERE l.force_id = f.id AND l.leave_type != ? AND l.from_date <= ? AND(l.to_date IS NULL OR l.to_date >= ?)) LIMIT ? OFFSET ? ';
    params.add(limit == -1 ? null : limit);
    params.add(offset);
    final results = db.select(query, params);
    return results.map((row) => Force.fromMap(row)).toList();
  }

  List<Leave> getLeavesByForceId(int forceId) {
    final results = db.select(
        'SELECT * FROM leaves WHERE force_id = ? ORDER BY id DESC', [forceId]);
    return results.map((row) => Leave.fromMap(row)).toList();
  }

  Future<List<Leave>> getLeavesByDateAndUnits(
      int date, List<int> unitIds, bool inUnitIds) async {
    final results = db.select(
      'SELECT l.* FROM leaves l JOIN forces s ON l.force_id = s.id WHERE s.unit_id ${inUnitIds ? '' : 'NOT '}IN(${unitIds.join(',')}) AND l.leave_type != ? AND(l.to_date IS NULL OR l.to_date >= ?) ORDER BY l.to_date',
      [LeaveType.hourly.name, date],
    );
    return results.map((row) => Leave.fromMap(row)).toList();
  }

  Leave? getLastLeaveByDate(int forceId, int dateTs) {
    final results = db.select(
      'SELECT * FROM leaves WHERE force_id = ? AND leave_type != ? AND to_date IS NOT NULL AND to_date <= ? LIMIT 1',
      [forceId, LeaveType.hourly.name, dateTs],
    );
    if (results.isEmpty) return null;
    return Leave.fromMap(results.first);
  }

  void addLeave(Leave leave) {
    db.execute(
        'INSERT INTO leaves(force_id, from_date, to_date, leave_type, details) VALUES(?, ?, ?, ?, ?) ',
        [
          leave.forceId,
          leave.fromDate,
          leave.toDate,
          leave.leaveType.name,
          leave.detailsStrJson
        ]);
  }

  void updateLeave(int id, Leave newLeave) {
    db.execute(
      'UPDATE leaves SET force_id = ?, from_date = ?, to_date = ?, leave_type = ?, details = ? WHERE id = ? ',
      [
        newLeave.forceId,
        newLeave.fromDate,
        newLeave.toDate,
        newLeave.leaveType.name,
        newLeave.detailsStrJson,
        id,
      ],
    );
  }

  void deleteLeave(int id) {
    db.execute('DELETE FROM leaves WHERE id = ?', [id]);
  }

  void addNote(int forceId, String note, int priority) {
    db.execute(
      'INSERT INTO notes(force_id, note, note_date, priority) VALUES(?, ?, ?, ?)',
      [forceId, note, dateTimestamp(), priority],
    );
  }

  Future<List<Note>> getNotesByForceId(int forceId) async {
    final results = db.select(
        'SELECT * FROM notes WHERE force_id = ? ORDER BY priority DESC,id DESC',
        [forceId]);
    return results.map((row) => Note.fromMap(row)).toList();
  }

  int addUnit(String name, int maxUsage, String description) {
    db.execute(
      'INSERT INTO units(name,max_usage,description) VALUES(?,?,?)',
      [name, maxUsage, description],
    );
    return db.lastInsertRowId;
  }

  Future<List<Unit>> getAllUnits() async {
    final results = db.select('SELECT * FROM units');
    return results.map((row) => Unit.fromMap(row)).toList();
  }

  void updateUnit(Unit unit) {
    db.execute(
      'UPDATE units SET name = ?,max_usage = ?,description = ? WHERE id = ?',
      [unit.name, unit.maxUsage, unit.description, unit.id],
    );
  }

  bool canDeleteUnit(int id) {
    if (id == 0 || id == 1 || id == 2) return false;
    final forces = db.select(
        'SELECT EXISTS(SELECT 1 FROM forces WHERE unit_id = ?)',
        [id]).first[0] as int;
    return forces == 0;
  }

  void deleteUnit(int id) {
    if (canDeleteUnit(id)) {
      db.execute('DELETE FROM units WHERE id = ?', [id]);
    } else {
      throw Exception('واحد قابل حذف نیست زیرا به نیرو یا مکان متصل است');
    }
  }

  int addState(State stateData) {
    db.execute(
      'INSERT INTO states(name, is_active, is_armed, state_type, unit_id) VALUES(?, ?, ?, ?, ?) ',
      [
        stateData.name,
        stateData.isActive ? 1 : 0,
        stateData.isArmed ? 1 : 0,
        stateData.stateType.name,
        stateData.unitId,
      ],
    );
    return db.lastInsertRowId;
  }

  Future<List<State>> getAllStates() async {
    final results = db.select('SELECT * FROM states');
    return results.map((row) => State.fromMap(row)).toList();
  }

  Future<State?> getStateById(int id) async {
    final results = db.select('SELECT * FROM states WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return State.fromMap(results.first);
  }

  void updateState(State stateData) {
    db.execute(
      'UPDATE states SET name = ?, is_active = ?, is_armed = ?, state_type = ?, unit_id = ? WHERE id = ? ',
      [
        stateData.name,
        stateData.isActive ? 1 : 0,
        stateData.isArmed ? 1 : 0,
        stateData.stateType.name,
        stateData.unitId,
        stateData.id!!,
      ],
    );
  }

  bool canDeleteState(int id) {
    final posts = db.select(
        'SELECT EXISTS(SELECT 1 FROM posts WHERE state_id = ?)',
        [id]).first[0] as int;
    return posts == 0;
  }

  void deleteState(int id) {
    if (canDeleteState(id)) {
      db.execute('DELETE FROM states WHERE id = ?', [id]);
    } else {
      throw Exception('مکان قابل حذف نیست زیرا در پست‌ها استفاده شده است');
    }
  }

  void savePost(Post post) {
    db.execute(
      'INSERT INTO posts(force_id, state_id, state_name, state_type, post_no, post_date, post_status, post_description) VALUES(?, ?, ?, ?, ?, ?, ?, ?) ',
      [
        post.forceId,
        post.stateId,
        post.stateName,
        post.stateType.name,
        post.postNo,
        post.postDate,
        post.postStatus.name,
        post.postDescription,
      ],
    );
  }

  void savePostsDoc(List<PostDoc> postsDoc, int date) {
    db.execute(
      'INSERT INTO posts_doc(doc_json, post_date) VALUES(?, ?)',
      [
        jsonEncode(postsDoc.map((p) => p.toMap()).toList()),
        date,
      ],
    );
  }

  List<Post> getPostsByDate(int dateTs) {
    final results =
        db.select('SELECT * FROM posts WHERE post_date = ?', [dateTs]);
    return results.map((row) => Post.fromMap(row)).toList();
  }

  int getPostsCountByForceId(int forceId) {
    final results = db.select(
        'SELECT COUNT(*) as total FROM posts WHERE force_id = ?', [forceId]);
    return results.first['total'] as int;
  }

  List<PostDoc> getPostsDocByDate(int dateTs) {
    final results = db
        .select('SELECT doc_json FROM posts_doc WHERE post_date = ?', [dateTs]);
    if (results.isEmpty) return [];
    return (jsonDecode(results.first['doc_json']) as List)
        .map((row) => PostDoc.fromMap(row))
        .toList();
  }

  Future<List<Post>> getPostsByForceId(int forceId) async {
    final results = db.select(
        'SELECT * FROM posts WHERE force_id = ? ORDER BY post_date DESC',
        [forceId]);
    return results.map((row) => Post.fromMap(row)).toList();
  }

  Future<List<Post>> getRangePostsByTs(int startTs, int endTs) async {
    final results = db.select(
        'SELECT * FROM posts WHERE post_date BETWEEN ? AND ?',
        [startTs, endTs]);
    return results.map((row) => Post.fromMap(row)).toList();
  }

  void deletePosts(int postDate) {
    db.execute('DELETE FROM posts WHERE post_date = ?', [postDate]);
    db.execute('DELETE FROM posts_doc WHERE post_date = ?', [postDate]);
  }

  int getLastPostNo(int forceId, StateType stateType, int dateTs) {
    final results = db.select(
      'SELECT post_no FROM posts WHERE force_id = ? AND post_date < ? AND state_id IN(SELECT id FROM states WHERE state_type = ?) ORDER BY post_date DESC LIMIT 1 ',
      [forceId, dateTs, stateType.name],
    );
    return results.isNotEmpty ? results.first['post_no'] as int : 0;
  }

  int? getLastPostDate(int forceId, int dateTs) {
    final results = db.select(
      'SELECT MAX(post_date) AS last_post_date FROM posts WHERE force_id = ? AND post_date < ?',
      [forceId, dateTs],
    );
    return results.first['last_post_date'] as int?;
  }

  Future<int> getLastDateLeave(int forceId) async {
    final results = db.select(
      'SELECT to_date FROM leaves WHERE force_id = ? AND leave_type IN(?,?,?) ORDER BY to_date DESC LIMIT 1',
      [
        forceId,
        LeaveType.presence.name,
        LeaveType.sick.name,
        LeaveType.absent.name
      ],
    );
    if (results.isEmpty || results.first['to_date'] == null) return 0;
    return results.first['to_date'] as int;
  }

  Future<Post?> getLastPost(int forceId) async {
    final results = db.select(
      'SELECT * FROM posts WHERE force_id = ? ORDER BY post_date DESC LIMIT 1',
      [forceId],
    );
    if (results.isEmpty) return null;
    return Post.fromMap(results.first);
  }
}
