import 'package:flutter/foundation.dart';

/// Public VPS hostname. Transglobe is on **:8085** (port 80 is used by another vhost).
const String kVpsPublicHost = '72.61.172.182';

const int kVpsPublicPort = 8085;

/// API base origin (no trailing path). Append `/api/...` for REST.
const String kVpsApiOrigin = 'http://$kVpsPublicHost:$kVpsPublicPort';

/// True when opened from Transglobe’s nginx vhost (must include `:8085`, not plain `:80`).
bool get isVpsDeployedWeb =>
    kIsWeb &&
    Uri.base.host.toLowerCase() == kVpsPublicHost &&
    Uri.base.port == kVpsPublicPort;
