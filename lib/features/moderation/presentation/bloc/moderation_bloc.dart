import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/usecases/get_reports.dart';
import 'moderation_event.dart';
import 'moderation_state.dart';

/// Lista de reportes del panel de moderación, filtrada por estado.
class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  final GetReports getReports;

  ReportStatus _filter = ReportStatus.pending;

  ModerationBloc({required this.getReports})
    : super(const ModerationInitial()) {
    on<ModerationStarted>((_, emit) => _load(emit, ReportStatus.pending));
    on<ModerationFilterChanged>((event, emit) => _load(emit, event.status));
    on<ModerationRefreshed>((_, emit) => _load(emit, _filter));
  }

  Future<void> _load(Emitter<ModerationState> emit, ReportStatus filter) async {
    _filter = filter;
    emit(ModerationLoading(filter));

    final result = await getReports(GetReportsParams(status: filter));
    result.fold(
      (failure) => emit(
        failure is ForbiddenFailure
            ? const ModerationForbidden()
            : ModerationFailure(filter: filter, message: failure.message),
      ),
      (reports) => emit(ModerationLoaded(filter: filter, reports: reports)),
    );
  }
}
