import 'package:flutter/material.dart';

/// Every icon the app draws, named for what it means rather than what it looks
/// like.
///
/// Screens reference these and never `Icons.*` directly, so swapping the set
/// later — for a brand set, Lucide, Phosphor — is an edit to this file alone.
/// Material Icons ship with Flutter, so this costs no dependency and nothing
/// to download.
class JhIcons {
  JhIcons._();

  // Brand and chrome
  static const logo = Icons.home_rounded;
  static const back = Icons.arrow_back_rounded;
  static const forward = Icons.arrow_forward_rounded;
  static const chevron = Icons.chevron_right_rounded;
  static const help = Icons.help_outline_rounded;
  static const search = Icons.search_rounded;
  static const notifications = Icons.notifications_none_rounded;
  static const language = Icons.translate_rounded;
  static const wave = Icons.waving_hand_rounded;

  // Tabs
  static const tabHome = Icons.home_rounded;
  static const tabShop = Icons.storefront_rounded;
  static const tabOrders = Icons.receipt_long_rounded;
  static const tabAccount = Icons.person_rounded;

  // Quick actions
  static const shop = Icons.storefront_rounded;
  static const track = Icons.local_shipping_rounded;
  static const nearby = Icons.place_rounded;
  static const favourites = Icons.star_rounded;

  // Status and content
  static const parcel = Icons.inventory_2_outlined;
  static const fastDelivery = Icons.bolt_rounded;
  static const verified = Icons.verified_rounded;
  static const logout = Icons.logout_rounded;
  static const phone = Icons.smartphone_rounded;
  static const changeNumber = Icons.sync_alt_rounded;
  static const calendar = Icons.event_rounded;
  static const comingSoon = Icons.construction_rounded;
  static const payment = Icons.payments_rounded;
  static const globe = Icons.public_rounded;

  // Account
  static const identityUnknown = Icons.question_mark_rounded;
  static const fullName = Icons.badge_outlined;
  static const email = Icons.mail_outline_rounded;
  static const lock = Icons.lock_outline_rounded;
  static const delete = Icons.delete_outline_rounded;

  // Orders
  static const box = Icons.inventory_2_rounded;
  static const minus = Icons.remove_rounded;
  static const plus = Icons.add_rounded;
  static const check = Icons.check_rounded;
  static const mapPin = Icons.location_on_rounded;
  static const myLocation = Icons.my_location_rounded;
  static const route = Icons.route_rounded;
  static const recipient = Icons.person_outline_rounded;
  static const timeline = Icons.timeline_rounded;
  static const star = Icons.star_rounded;
  static const call = Icons.call_rounded;
  static const edit = Icons.edit_outlined;
  static const recent = Icons.history_rounded;
  static const camera = Icons.photo_camera_outlined;
  static const gallery = Icons.image_outlined;
  static const removePhoto = Icons.close_rounded;

  static const motorcycle = Icons.two_wheeler_rounded;
  static const bajaji = Icons.electric_rickshaw_rounded;
  static const van = Icons.local_shipping_rounded;
  static const car = Icons.directions_car_rounded;

  static const pkgDocuments = Icons.description_outlined;
  static const pkgClothes = Icons.checkroom_rounded;
  static const pkgFood = Icons.lunch_dining_rounded;
  static const pkgElectronics = Icons.devices_other_rounded;
  static const pkgHousehold = Icons.chair_outlined;
  static const pkgOther = Icons.edit_rounded;
}
