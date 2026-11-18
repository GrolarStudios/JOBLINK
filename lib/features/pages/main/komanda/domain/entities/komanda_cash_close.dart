class KomandaCashClose {
  final String id;
  final DateTime openedAt;
  final DateTime closedAt;
  final double openingCash;
  final double cashTotal;
  final double cardTotal;
  final double transferTotal;
  final double tipsTotal;
  final double expectedTotal;
  final double countedCash;
  final double difference;
  final int paidOrders;
  final String notes;
  final bool allowMultiple;
  const KomandaCashClose({required this.id,required this.openedAt,required this.closedAt,this.openingCash=0,required this.cashTotal,required this.cardTotal,required this.transferTotal,required this.tipsTotal,required this.expectedTotal,required this.countedCash,required this.difference,required this.paidOrders,this.notes='',this.allowMultiple=false});
}
