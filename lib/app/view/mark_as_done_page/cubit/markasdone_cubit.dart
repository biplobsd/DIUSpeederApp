import 'package:bloc/bloc.dart';
import 'package:diuspeeder/core/auth_BLC/cubit/authblc_cubit.dart';
import 'package:diuspeeder/core/auth_BLC/model/course_data.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

part 'markasdone_state.dart';

class MarkasdoneCubit extends Cubit<MarkasdoneState> {
  MarkasdoneCubit({required this.authblcCubit})
      : super(MarkasdoneInitalState()) {
    gettingData();
  }

  late List<CourseData> course;
  AuthblcCubit authblcCubit;
  Map<String, dynamic>? markButtons;
  bool iswebAccess = false;

  Future<void> gettingData() async {
    emit(MarkasdoneGettingDataState());
    iswebAccess = await authblcCubit.blcApi.webAccess();
    course = await authblcCubit.blcApi.getrecentCourses();
    emit(MarkasdoneIdealState());
  }

  Future<void> refresh(String? pageId) async {
    await gettingData();
    if (pageId != null) {
      await gettingDoneButtons(pageId);
    }
  }

  Future<void> gettingDoneButtons(String pageId) async {
    if (iswebAccess) {
      emit(MarkasdoneGettingButtonsState());
      markButtons = await authblcCubit.blcApi.markAsDoneGetButton(pageId);
      buttonsStates();
    }
  }

  double getProgressBarValue() {
    final doneAlready = markButtons!['markButtons'].fold(0,
        (dynamic previousValue, dynamic element) {
      if (element['isMarkDone'] as bool) {
        return previousValue + 1;
      }
      return previousValue;
    }) as num;
    final length = (markButtons!['markButtons'] as List).length;
    return doneAlready / length;
  }

  Future<void> markAsDone(
    String sesskey,
    String cmid,
    String pageId,
    bool current,
  ) async {
    emit(MarkasdoneLoadingState());
    var i = 0;
    for (; i < (markButtons!['markButtons'] as List).length; i++) {
      dynamic target = markButtons!['markButtons'][i];
      if (target['cmid'] == cmid) {
        target['isSending'] = true;
        break;
      }
    }
    if (await authblcCubit.blcApi.markAsDone(sesskey, cmid, current)) {
      markButtons!['markButtons'][i]['isMarkDone'] = current;
      markButtons!['markButtons'][i]['isSending'] = false;
    }
    buttonsStates();
  }

  bool buttonsStates() {
    for (final item in markButtons!['markButtons']) {
      if (!(item['isMarkDone'] as bool)) {
        emit(MarkasdoneUnmarkState());
        return false;
      }
    }
    emit(MarkasdoneMarkState());
    return true;
  }

  Future<void> markAll() async {
    emit(MarkasdoneLoadingState());

    var isAllDone = buttonsStates();

    markButtons!['markButtons'].forEach((dynamic element) async {});
    var markAsDone = authblcCubit.blcApi.markAsDone;
    for (var i = 0; i < (markButtons!['markButtons'] as List).length; i++) {
      dynamic element = markButtons!['markButtons'][i];
      final sesskey = markButtons!['sesskey'].toString();
      final cmid = element['cmid'].toString();
      final isDone = (element['isMarkDone'] as bool);

      if (isAllDone) {
        if (await markAsDone(
          sesskey,
          cmid,
          false,
        )) {
          element['isMarkDone'] = false;
        }
      } else {
        if (!isDone) {
          if (await markAsDone(
            sesskey,
            cmid,
            true,
          )) {
            element['isMarkDone'] = true;
          }
        }
      }
      emit(MarkasdoneLoadingState());
    }
    buttonsStates();
  }
}
