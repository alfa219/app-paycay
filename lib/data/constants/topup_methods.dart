import 'package:flutter/material.dart';

class TopupMethod {
  final String id;
  final String kind;
  final String name;
  final String sub;
  final int fee;
  final String account;
  final String logo;
  final IconData? iconData;
  final int colorHex;

  const TopupMethod({
    required this.id,
    required this.kind,
    required this.name,
    required this.sub,
    required this.fee,
    required this.account,
    required this.logo,
    this.iconData,
    required this.colorHex,
  });

  bool get isAuto => id == 'bca' || kind == 'ewallet';
}

const kTopupMethods = <TopupMethod>[
  TopupMethod(
    id: 'bca',
    kind: 'bank',
    name: 'BCA Virtual Account',
    sub: 'Otomatis · Instan',
    fee: 0,
    account: '8829 1234 5678',
    logo: 'BCA',
    colorHex: 0xFF0060A9,
  ),
  TopupMethod(
    id: 'mandiri',
    kind: 'bank',
    name: 'Mandiri Transfer',
    sub: 'Manual · Verifikasi 1×24 jam',
    fee: 0,
    account: '1234 5678 9012',
    logo: 'MDR',
    colorHex: 0xFF003D79,
  ),
  TopupMethod(
    id: 'gopay',
    kind: 'ewallet',
    name: 'GoPay',
    sub: 'Instan',
    fee: 1500,
    account: '+62 812 3456 7890',
    logo: 'GO',
    colorHex: 0xFF00AED6,
  ),
  TopupMethod(
    id: 'ovo',
    kind: 'ewallet',
    name: 'OVO',
    sub: 'Instan',
    fee: 1500,
    account: '+62 812 3456 7890',
    logo: 'OVO',
    colorHex: 0xFF4C2A86,
  ),
  TopupMethod(
    id: 'rfid',
    kind: 'rfid',
    name: 'Tap Kartu RFID',
    sub: 'Top up langsung di stasiun',
    fee: 0,
    account: 'Tap di reader stasiun',
    logo: '',
    iconData: Icons.contactless_rounded,
    colorHex: 0xFFFF6B2C,
  ),
];
