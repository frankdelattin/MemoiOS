import 'package:equatable/equatable.dart';

abstract class NlpSearchEvent extends Equatable {}

class NlpSearch extends NlpSearchEvent {
  final String query;

  NlpSearch({required this.query});

  @override
  List<Object?> get props => [query];
}
