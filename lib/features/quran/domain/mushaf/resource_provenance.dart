import 'package:meta/meta.dart';

enum QuranResourceType {
  canonicalQuran,
  wordDataset,
  mushafLayout,
  quranScript,
  quranFont,
  mushafVectorPages,
  pageAssets,
  tafsir,
  wordMeaning,
  audio,
  audioTiming,
}

enum CommercialUseStatus { unknown, allowed, restricted, prohibited }

enum RedistributionStatus { unknown, allowed, restricted, prohibited }

enum ProductionApprovalStatus { researchOnly, pending, approved, rejected }

@immutable
final class ResourceCompatibility {
  const ResourceCompatibility({
    this.riwayahIds = const {},
    this.mushafEditionIds = const {},
    this.quranCoreVersions = const {},
  });

  final Set<String> riwayahIds;
  final Set<String> mushafEditionIds;
  final Set<String> quranCoreVersions;
}

@immutable
final class QuranResourceProvenance {
  const QuranResourceProvenance({
    required this.resourceId,
    required this.resourceType,
    required this.provider,
    required this.sourceReference,
    required this.version,
    required this.acquiredAt,
    required this.sourceChecksum,
    required this.licenseReference,
    required this.commercialUseStatus,
    required this.redistributionStatus,
    required this.attribution,
    required this.productionApprovalStatus,
    required this.compatibility,
  });

  final String resourceId;
  final QuranResourceType resourceType;
  final String provider;
  final String sourceReference;
  final String version;
  final DateTime acquiredAt;
  final String sourceChecksum;
  final String licenseReference;
  final CommercialUseStatus commercialUseStatus;
  final RedistributionStatus redistributionStatus;
  final String attribution;
  final ProductionApprovalStatus productionApprovalStatus;
  final ResourceCompatibility compatibility;

  bool get researchEligible =>
      productionApprovalStatus != ProductionApprovalStatus.rejected;

  bool get productionEligible =>
      productionApprovalStatus == ProductionApprovalStatus.approved &&
      commercialUseStatus == CommercialUseStatus.allowed &&
      redistributionStatus == RedistributionStatus.allowed;

  List<String> validate({required bool forProduction}) {
    final issues = <String>[];
    final required = <String, String>{
      'resourceId': resourceId,
      'provider': provider,
      'sourceReference': sourceReference,
      'version': version,
      'sourceChecksum': sourceChecksum,
      'licenseReference': licenseReference,
      'attribution': attribution,
    };
    for (final entry in required.entries) {
      if (entry.value.trim().isEmpty) issues.add('${entry.key} is required');
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceChecksum)) {
      issues.add('sourceChecksum must be a lowercase SHA-256');
    }
    if (forProduction && !productionEligible) {
      issues.add('resource is not approved for commercial redistribution');
    }
    return List.unmodifiable(issues);
  }
}
