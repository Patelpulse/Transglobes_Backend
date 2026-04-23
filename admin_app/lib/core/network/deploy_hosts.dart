import 'package:flutter/foundation.dart';

/// Public VPS hostname.
const String kVpsPublicHost = '72.61.172.182';

const int kVpsPublicPort = 2020;

/// API base origin (no trailing path). Append `/api/...` for REST.
const String kVpsApiOrigin = 'http://$kVpsPublicHost:$kVpsPublicPort';

/// True when opened from Transglobe API host.
bool get isVpsDeployedWeb =>
    kIsWeb &&
    Uri.base.host.toLowerCase() == kVpsPublicHost &&
    Uri.base.port == kVpsPublicPort;
