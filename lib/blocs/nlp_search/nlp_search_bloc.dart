import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_event.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_state.dart';
import 'package:snapp_app/services/vector_service.dart';

class NlpSearchBloc extends Bloc<NlpSearchEvent, NlpSearchState> {
  final VectorService _vectorService;

  NlpSearchBloc({required VectorService vectorService})
      : _vectorService = vectorService,
        super(NlpSearchInitial()) {
    on<NlpSearch>(_onNlpSearch);
  }

  void _onNlpSearch(NlpSearch event, Emitter<NlpSearchState> emit) async {
    if (event.query.isEmpty) {
      emit(NlpSearchInitial());
      return;
    }
    emit(NlpSearchLoading(query: event.query));
    try {
      final results = await _vectorService.getSimilarPhotos(event.query);
      emit(NlpSearchLoaded(results: results));
    } catch (e) {
      emit(NlpSearchError(error: e.toString()));
    }
  }
}
