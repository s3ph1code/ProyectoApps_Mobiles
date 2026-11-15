import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_activity_by_id.dart';
import 'activity_detail_event.dart';
import 'activity_detail_state.dart';

/// Detalle de una actividad. El id lo trae la ruta, así que el BLoC no lo
/// guarda: cada petición dice cuál cargar.
class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final GetActivityById getActivityById;

  ActivityDetailBloc({required this.getActivityById})
    : super(const ActivityDetailInitial()) {
    on<ActivityDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    ActivityDetailRequested event,
    Emitter<ActivityDetailState> emit,
  ) async {
    if (state is ActivityDetailLoading) return;
    emit(const ActivityDetailLoading());

    final result = await getActivityById(
      GetActivityByIdParams(activityId: event.activityId),
    );

    result.fold(
      (failure) => emit(
        failure is ActivityNotFoundFailure
            ? ActivityDetailNotFound(failure.message)
            : ActivityDetailFailure(failure.message),
      ),
      (activity) => emit(ActivityDetailLoaded(activity)),
    );
  }
}
