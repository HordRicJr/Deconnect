class Organization {
  final String id;
  final String name;
  final String slug;
  final String? domain;
  final int maxUsers;
  final List<String>? allowedDomains;
  final bool ssoEnabled;
  final String? ssoProvider;
  final Map<String, dynamic> ssoConfig;
  final String? logoUrl;
  final String primaryColor;
  final Map<String, dynamic> themeConfig;
  final String? billingEmail;
  final Map<String, dynamic> billingContact;
  final bool isActive;
  final DateTime? trialEndsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.domain,
    this.maxUsers = 100,
    this.allowedDomains,
    this.ssoEnabled = false,
    this.ssoProvider,
    this.ssoConfig = const {},
    this.logoUrl,
    this.primaryColor = '#3B82F6',
    this.themeConfig = const {},
    this.billingEmail,
    this.billingContact = const {},
    this.isActive = true,
    this.trialEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      domain: json['domain'] as String?,
      maxUsers: json['max_users'] as int? ?? 100,
      allowedDomains: json['allowed_domains'] != null
          ? List<String>.from(json['allowed_domains'])
          : null,
      ssoEnabled: json['sso_enabled'] as bool? ?? false,
      ssoProvider: json['sso_provider'] as String?,
      ssoConfig: json['sso_config'] as Map<String, dynamic>? ?? {},
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String? ?? '#3B82F6',
      themeConfig: json['theme_config'] as Map<String, dynamic>? ?? {},
      billingEmail: json['billing_email'] as String?,
      billingContact: json['billing_contact'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'domain': domain,
      'max_users': maxUsers,
      'allowed_domains': allowedDomains,
      'sso_enabled': ssoEnabled,
      'sso_provider': ssoProvider,
      'sso_config': ssoConfig,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'theme_config': themeConfig,
      'billing_email': billingEmail,
      'billing_contact': billingContact,
      'is_active': isActive,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
