import 'package:section_management/models/enums.dart';

class Post {
  int? id;
  int forceId;
  int stateId;
  String stateName;
  StateType stateType;
  int postNo;
  int postDate;
  PostStatus postStatus;
  String postDescription;
  List<String>? warnings = null;
  bool hasError = false;

  Post({
    this.id,
    required this.forceId,
    required this.stateId,
    required this.stateName,
    required this.stateType,
    required this.postNo,
    required this.postDate,
    required this.postStatus,
    required this.postDescription,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      forceId: map['force_id'],
      stateId: map['state_id'],
      stateName: map['state_name'],
      stateType:
          StateType.values.firstWhere((s) => s.name == map['state_type']),
      postStatus:
          PostStatus.values.firstWhere((s) => s.name == map['post_status']),
      postNo: map['post_no'],
      postDate: map['post_date'],
      postDescription: map['post_description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'force_id': forceId,
      'state_id': stateId,
      'state_name': stateName,
      'state_type': stateType.name,
      'post_no': postNo,
      'post_date': postDate,
      'post_status': postStatus.name,
      'post_description': postDescription,
    };
  }
}
