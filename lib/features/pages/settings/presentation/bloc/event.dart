abstract class BaseEvent {}

class FetchHistoryExitEvent extends BaseEvent {}
class FilterHistoryExitEvent extends BaseEvent {
  final String query;
  final List<Map<String, dynamic>> _filteredData;

  FilterHistoryExitEvent(this.query,this._filteredData);
}