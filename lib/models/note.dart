class Note {
  final int? id;
  final int forceId;
  final String note;
  final int noteDate;

  Note({
    this.id,
    required this.forceId,
    required this.note,
    required this.noteDate,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      forceId: map['force_id'],
      note: map['note'],
      noteDate: map['note_date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'force_id': forceId,
      'note': note,
      'note_date': noteDate,
    };
  }
}
