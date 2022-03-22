import 'dart:convert';
import 'dart:developer';

import 'package:json_annotation/json_annotation.dart';

import 'QuizResponse.dart';

part 'LessonResponse.g.dart';

@JsonSerializable()
class LessonResponse {
  dynamic id;
  SectionBean? section;
  String title;
  String type;
  String content;
  String video;
  String video_poster;
  String prev_lesson_type;
  String next_lesson_type;
  String prev_lesson;
  String next_lesson;
  bool completed;
  bool next_lesson_available;
  String view_link;
  List<Quiz_dataBean?> quiz_data = [];
  num time;
  num time_left;
  late bool fromCache;
  dynamic quiz_time;

  LessonResponse({
    this.id,
    required this.section,
    required this.title,
    required this.type,
    required this.content,
    required this.video,
    required this.video_poster,
    required this.prev_lesson_type,
    required this.next_lesson_type,
    required this.prev_lesson,
    required this.next_lesson,
    required this.completed,
    required this.next_lesson_available,
    required this.view_link,
    // required this.quiz_data,
    required this.time,
    required this.time_left,
    this.quiz_time,
    required this.fromCache,
  });


  factory LessonResponse.fromJson(Map<String, dynamic> json) => _$LessonResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LessonResponseToJson(this);
}

@JsonSerializable()
class SectionBean {
  final dynamic label;
  final dynamic number;
  final dynamic index;

  SectionBean({this.label, this.number, this.index});

  factory SectionBean.fromJson(Map<String, dynamic> json) => _$SectionBeanFromJson(json);

  Map<String, dynamic> toJson() => _$SectionBeanToJson(this);
}
