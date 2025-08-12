import 'package:equatable/equatable.dart';
import 'package:snapp_app/data/nlp_image.dart';

abstract class NlpSearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NlpSearchInitial extends NlpSearchState {}

class NlpSearchLoading extends NlpSearchState {
  final String query;

  NlpSearchLoading({required this.query});

  @override
  List<Object?> get props => [query];
}

class NlpSearchLoaded extends NlpSearchState {
  final List<ImagePrediction> results;

  NlpSearchLoaded({required this.results});

  @override
  List<Object?> get props => [results];
}

class NlpSearchError extends NlpSearchState {
  final String error;

  NlpSearchError({required this.error});

  @override
  List<Object?> get props => [error];
}
