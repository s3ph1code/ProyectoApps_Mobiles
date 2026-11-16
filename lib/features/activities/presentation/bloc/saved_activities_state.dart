import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';

sealed class SavedActivitiesState extends Equatable {
  const SavedActivitiesState();

  @override
  List<Object?> get props => [];
}

class SavedActivitiesInitial extends SavedActivitiesState {
  const SavedActivitiesInitial();
}

class SavedActivitiesLoading extends SavedActivitiesState {
  const SavedActivitiesLoading();
}

class SavedActivitiesLoaded extends SavedActivitiesState {
  final List<Activity> activities;
  final Set<String> savedIds;
  final String? noticeMessage;

  const SavedActivitiesLoaded({
    required this.activities,
    required this.savedIds,
    this.noticeMessage,
  });

  bool get isEmpty => activities.isEmpty;

  bool isSaved(String activityId) => savedIds.contains(activityId);

  SavedActivitiesLoaded copyWith({
    List<Activity>? activities,
    Set<String>? savedIds,
    String? Function()? noticeMessage,
  }) {
    return SavedActivitiesLoaded(
      activities: activities ?? this.activities,
      savedIds: savedIds ?? this.savedIds,
      noticeMessage: noticeMessage != null ? noticeMessage() : this.noticeMessage,
    );
  }

  @override
  List<Object?> get props => [activities, savedIds, noticeMessage];
}

class SavedActivitiesFailure extends SavedActivitiesState {
  final String message;

  const SavedActivitiesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
