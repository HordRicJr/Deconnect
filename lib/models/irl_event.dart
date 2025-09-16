class IrlEvent {
  final String id;
  final String? organizationId;
  final String title;
  final String? description;
  final String eventType;
  final String? category;
  final String? locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? startTime; // Alias pour startsAt pour compatibilité
  final int? maxParticipants;
  final int participantsCount;
  final String qrCode;
  final int validationRadius;
  final int xpReward;
  final int socialPointsReward;
  final List<String>? badgesReward;
  final String? organizerId;
  final bool isPublic;
  final bool requiresApproval;
  final String status;
  final DateTime createdAt;

  const IrlEvent({
    required this.id,
    this.organizationId,
    required this.title,
    this.description,
    required this.eventType,
    this.category,
    this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.startsAt,
    required this.endsAt,
    this.startTime,
    this.maxParticipants,
    this.participantsCount = 0,
    required this.qrCode,
    this.validationRadius = 100,
    this.xpReward = 0,
    this.socialPointsReward = 0,
    this.badgesReward,
    this.organizerId,
    this.isPublic = true,
    this.requiresApproval = false,
    this.status = 'upcoming',
    required this.createdAt,
  });

  factory IrlEvent.fromJson(Map<String, dynamic> json) {
    final startsAt = DateTime.parse(json['starts_at']);
    return IrlEvent(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String,
      category: json['category'] as String?,
      locationName: json['location_name'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      startsAt: startsAt,
      endsAt: DateTime.parse(json['ends_at']),
      startTime: startsAt, // Utiliser startsAt comme alias
      maxParticipants: json['max_participants'] as int?,
      participantsCount: json['participants_count'] as int? ?? 0,
      qrCode: json['qr_code'] as String,
      validationRadius: json['validation_radius'] as int? ?? 100,
      xpReward: json['xp_reward'] as int? ?? 0,
      socialPointsReward: json['social_points_reward'] as int? ?? 0,
      badgesReward: json['badges_reward'] != null
          ? List<String>.from(json['badges_reward'])
          : null,
      organizerId: json['organizer_id'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      status: json['status'] as String? ?? 'upcoming',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'category': category,
      'location_name': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'max_participants': maxParticipants,
      'participants_count': participantsCount,
      'qr_code': qrCode,
      'validation_radius': validationRadius,
      'xp_reward': xpReward,
      'social_points_reward': socialPointsReward,
      'badges_reward': badgesReward,
      'organizer_id': organizerId,
      'is_public': isPublic,
      'requires_approval': requiresApproval,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IrlEvent copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? description,
    String? eventType,
    String? category,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? startTime,
    int? maxParticipants,
    int? participantsCount,
    String? qrCode,
    int? validationRadius,
    int? xpReward,
    int? socialPointsReward,
    List<String>? badgesReward,
    String? organizerId,
    bool? isPublic,
    bool? requiresApproval,
    String? status,
    DateTime? createdAt,
  }) {
    return IrlEvent(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      category: category ?? this.category,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      startTime: startTime ?? this.startTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantsCount: participantsCount ?? this.participantsCount,
      qrCode: qrCode ?? this.qrCode,
      validationRadius: validationRadius ?? this.validationRadius,
      xpReward: xpReward ?? this.xpReward,
      socialPointsReward: socialPointsReward ?? this.socialPointsReward,
      badgesReward: badgesReward ?? this.badgesReward,
      organizerId: organizerId ?? this.organizerId,
      isPublic: isPublic ?? this.isPublic,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
