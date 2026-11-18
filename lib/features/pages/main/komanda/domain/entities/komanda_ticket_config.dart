class KomandaTicketConfig {
  final String businessName;
  final String address;
  final String phone;
  final String footer;
  final bool showFolio;
  final bool showWaiter;
  final bool showTable;
  final bool showDate;
  final bool showItemSpecifications;
  final bool showTip;
  final String plateLabel;
  final String logoBase64;
  final double fontScale;
  final int fontWeight;

  const KomandaTicketConfig({
    this.businessName = 'Mi restaurante',
    this.address = '',
    this.phone = '',
    this.footer = 'Gracias por su compra',
    this.showFolio = true,
    this.showWaiter = true,
    this.showTable = true,
    this.showDate = true,
    this.showItemSpecifications = true,
    this.showTip = true,
    this.plateLabel = 'Plato',
    this.logoBase64 = '',
    this.fontScale = 1.0,
    this.fontWeight = 400,
  });

  KomandaTicketConfig copyWith({
    String? businessName, String? address, String? phone, String? footer,
    bool? showFolio, bool? showWaiter, bool? showTable, bool? showDate,
    bool? showItemSpecifications, bool? showTip, String? plateLabel, String? logoBase64, double? fontScale, int? fontWeight,
  }) => KomandaTicketConfig(
    businessName: businessName ?? this.businessName,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    footer: footer ?? this.footer,
    showFolio: showFolio ?? this.showFolio,
    showWaiter: showWaiter ?? this.showWaiter,
    showTable: showTable ?? this.showTable,
    showDate: showDate ?? this.showDate,
    showItemSpecifications: showItemSpecifications ?? this.showItemSpecifications,
    showTip: showTip ?? this.showTip,
    plateLabel: plateLabel ?? this.plateLabel,
    logoBase64: logoBase64 ?? this.logoBase64,
    fontScale: fontScale ?? this.fontScale,
    fontWeight: fontWeight ?? this.fontWeight,
  );
}
