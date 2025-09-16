-- ===============================================
-- DECONNECT - Schema SQL Complet Multi-Tenant (VERSION CORRIGÉE)
-- Architecture Enterprise + Gamification Avancée
-- Compatible Supabase PostgreSQL - Sans dépendances externes
-- ===============================================

-- Extensions nécessaires (toutes compatibles Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===============================================
-- SCRIPT DE NETTOYAGE COMPLET (UTILISER AVEC PRÉCAUTION)
-- ===============================================
/*
⚠️  ATTENTION: LE SCRIPT CI-DESSOUS SUPPRIME TOUT ! ⚠️

-- Désactiver les vérifications temporairement
SET session_replication_role = replica;

-- Supprimer toutes les politiques RLS, triggers, fonctions, tables
DO $$ 
DECLARE r RECORD;
BEGIN
    -- Politiques RLS
    FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
    END LOOP;
    
    -- Triggers
    FOR r IN (SELECT event_object_schema, event_object_table, trigger_name FROM information_schema.triggers 
              WHERE event_object_schema = 'public' AND trigger_name NOT LIKE 'pg_%') LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', r.trigger_name, r.event_object_schema, r.event_object_table);
    END LOOP;
    
    -- Fonctions
    FOR r IN (SELECT n.nspname as schema_name, p.proname as function_name, pg_get_function_identity_arguments(p.oid) as function_args
              FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
              WHERE n.nspname = 'public' AND p.proname NOT LIKE 'pg_%' AND p.proname NOT LIKE 'uuid_%') LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE', r.schema_name, r.function_name, r.function_args);
    END LOOP;
    
    -- Tables
    FOR r IN (SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT LIKE 'pg_%') LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', r.schemaname, r.tablename);
    END LOOP;
END $$;

SET session_replication_role = DEFAULT;
*/

-- ===============================================
-- ORGANISATIONS ET MULTI-TENANT
-- ===============================================

-- Table des organisations (entreprises)
CREATE TABLE organizations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    domain VARCHAR(255), -- example.com pour validation email automatique
    
    -- Configuration
    max_users INTEGER DEFAULT 100,
    allowed_domains TEXT[], -- domaines d'emails autorisés
    sso_enabled BOOLEAN DEFAULT false,
    sso_provider VARCHAR(50), -- 'google', 'microsoft', 'okta'
    sso_config JSONB DEFAULT '{}',
    
    -- Branding
    logo_url TEXT,
    primary_color VARCHAR(7) DEFAULT '#3B82F6',
    theme_config JSONB DEFAULT '{}',
    
    -- Facturation
    billing_email VARCHAR(255),
    billing_contact JSONB DEFAULT '{}',
    
    -- État
    is_active BOOLEAN DEFAULT true,
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des plans d'abonnement organisation
CREATE TABLE organization_plans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
    
    -- Plan details
    plan_type VARCHAR(30) NOT NULL CHECK (plan_type IN ('trial', 'starter', 'business', 'enterprise')),
    price_per_user DECIMAL(10,2) NOT NULL DEFAULT 0,
    billing_interval VARCHAR(20) DEFAULT 'monthly' CHECK (billing_interval IN ('monthly', 'yearly')),
    
    -- Limites
    max_users INTEGER NOT NULL,
    features JSONB DEFAULT '{}', -- {"advanced_analytics": true, "custom_challenges": true}
    
    -- Facturation Stripe
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    stripe_price_id VARCHAR(255),
    
    -- Dates
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ends_at TIMESTAMP WITH TIME ZONE,
    next_billing_date TIMESTAMP WITH TIME ZONE,
    
    -- État
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'suspended')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des codes d'accès organisation
CREATE TABLE organization_invite_codes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    
    -- Limitations
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Métadonnées
    created_by UUID, -- Référence vers auth.users sans contrainte FK pour Supabase
    department VARCHAR(100),
    notes TEXT,
    
    -- État
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- UTILISATEURS ÉTENDUS
-- ===============================================

-- Table des profils utilisateurs (étend auth.users de Supabase)
CREATE TABLE profiles (
    id UUID PRIMARY KEY, -- Référence vers auth.users sans FK pour Supabase
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    avatar_url TEXT,
    phone VARCHAR(20),
    date_of_birth DATE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Organisation (pour les comptes entreprise)
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    organization_role VARCHAR(20) DEFAULT 'member' CHECK (organization_role IN ('member', 'admin', 'owner')),
    joined_organization_at TIMESTAMP WITH TIME ZONE,
    
    -- Rôle système
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'mentor', 'moderator', 'admin', 'super_admin')),
    
    -- Préférences utilisateur
    coach_tone VARCHAR(20) DEFAULT 'friendly' CHECK (coach_tone IN ('friendly', 'humorous', 'strict', 'motivational')),
    language VARCHAR(10) DEFAULT 'fr',
    theme VARCHAR(20) DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'auto')),
    
    -- Gamification AVANCÉE
    total_xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    focus_score DECIMAL(5,2) DEFAULT 0.0,
    
    -- Ligue et classement
    league VARCHAR(20) DEFAULT 'bronze' CHECK (league IN ('bronze', 'silver', 'gold', 'platinum', 'diamond', 'legendary')),
    league_points INTEGER DEFAULT 0,
    weekly_rank INTEGER,
    
    -- Avatar évolutif POUSSÉ
    avatar_type VARCHAR(20) DEFAULT 'tree' CHECK (avatar_type IN ('tree', 'animal', 'yogi', 'warrior', 'sage')),
    avatar_level INTEGER DEFAULT 1,
    avatar_health DECIMAL(3,2) DEFAULT 1.0, -- 0.0 = avatar dépérit, 1.0 = pleine forme
    avatar_customization JSONB DEFAULT '{}',
    avatar_accessories JSONB DEFAULT '[]', -- items débloqués
    
    -- Statistiques avancées
    total_focus_time INTEGER DEFAULT 0, -- minutes
    apps_blocked_count INTEGER DEFAULT 0,
    challenges_completed INTEGER DEFAULT 0,
    social_points INTEGER DEFAULT 0, -- points gagnés via événements IRL
    wellness_points INTEGER DEFAULT 0, -- points bien-être (hydratation, sport, etc.)
    
    -- Abonnement
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'enterprise', 'lifetime')),
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- IA et coaching
    ai_coaching_enabled BOOLEAN DEFAULT true,
    ai_personality_traits JSONB DEFAULT '{}', -- préférences pour personnaliser l'IA
    prediction_opt_in BOOLEAN DEFAULT true, -- accepte les prédictions comportementales
    
    -- Métadonnées
    onboarding_completed BOOLEAN DEFAULT false,
    privacy_settings JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- GAMIFICATION AVANCÉE
-- ===============================================

-- Table des ligues et saisons
CREATE TABLE leagues (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    level INTEGER NOT NULL, -- 1=Bronze, 2=Silver, etc.
    
    -- Seuils
    min_points INTEGER NOT NULL,
    max_points INTEGER,
    
    -- Apparence
    color VARCHAR(7) NOT NULL,
    icon_url TEXT,
    
    -- Récompenses ligue
    weekly_xp_bonus INTEGER DEFAULT 0,
    exclusive_badges UUID[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des saisons de classement
CREATE TABLE ranking_seasons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Configuration
    reset_points BOOLEAN DEFAULT true, -- reset les points en fin de saison
    rewards JSONB DEFAULT '{}', -- récompenses de fin de saison
    
    -- État
    is_active BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des classements par ligue et saison
CREATE TABLE league_rankings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    season_id UUID REFERENCES ranking_seasons(id) ON DELETE CASCADE NOT NULL,
    league_id UUID REFERENCES leagues(id) NOT NULL,
    
    -- Classement
    points INTEGER NOT NULL DEFAULT 0,
    rank_position INTEGER,
    
    -- Progression
    points_this_week INTEGER DEFAULT 0,
    rank_change INTEGER DEFAULT 0, -- +5 = monté de 5 places, -3 = descendu de 3 places
    
    -- Métadonnées
    week_number INTEGER, -- semaine dans la saison
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, season_id, week_number)
);

-- Table des badges ÉTENDUS avec rareté
CREATE TABLE badges (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    category VARCHAR(50), -- 'focus', 'streak', 'challenges', 'social', 'irl_events', 'wellness'
    
    -- Rareté et valeur
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythical')),
    xp_reward INTEGER DEFAULT 0,
    league_points_reward INTEGER DEFAULT 0,
    
    -- Conditions d'obtention
    unlock_conditions JSONB NOT NULL,
    
    -- Apparence et prestige
    glow_effect BOOLEAN DEFAULT false, -- effet visuel spécial
    animated BOOLEAN DEFAULT false,
    
    -- Exclusivité
    is_secret BOOLEAN DEFAULT false,
    is_limited_time BOOLEAN DEFAULT false,
    available_until TIMESTAMP WITH TIME ZONE,
    max_recipients INTEGER, -- NULL = illimité
    current_recipients INTEGER DEFAULT 0,
    
    -- État
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des trophées (achievements spéciaux)
CREATE TABLE trophies (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    
    -- Valeur et rareté 
    xp_reward INTEGER DEFAULT 0,
    league_points_reward INTEGER DEFAULT 0,
    tier VARCHAR(20) DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
    
    -- Conditions
    unlock_conditions JSONB NOT NULL,
    
    -- Prestige
    grants_title VARCHAR(100), -- "Maître du Focus", "Gardien du Sommeil"
    
    -- Métadonnées
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- ÉVÉNEMENTS IRL ET IMPACT SOCIAL
-- ===============================================

-- Table des événements IRL (maraudes, méditation groupe, sport...)
CREATE TABLE irl_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Détails événement
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN ('sport', 'meditation', 'volunteer', 'culture', 'nature', 'social')),
    
    -- Localisation (coordonnées décimales simples)
    location_name VARCHAR(255),
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Planning
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    max_participants INTEGER,
    
    -- Validation
    qr_code VARCHAR(255) UNIQUE NOT NULL, -- pour validation présence
    validation_radius INTEGER DEFAULT 100, -- mètres autour de l'événement
    
    -- Récompenses
    xp_reward INTEGER DEFAULT 0,
    social_points_reward INTEGER DEFAULT 0,
    badges_reward UUID[],
    
    -- Organisation
    organizer_id UUID REFERENCES profiles(id),
    is_public BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT false,
    
    -- État
    status VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des participations aux événements IRL
CREATE TABLE irl_event_participations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_id UUID REFERENCES irl_events(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Statut participation
    status VARCHAR(20) DEFAULT 'registered' CHECK (status IN ('registered', 'attended', 'absent', 'cancelled')),
    
    -- Validation présence (coordonnées décimales simples)
    validated_at TIMESTAMP WITH TIME ZONE,
    validation_latitude DECIMAL(10, 8), -- latitude GPS de validation
    validation_longitude DECIMAL(11, 8), -- longitude GPS de validation
    qr_scanned BOOLEAN DEFAULT false,
    
    -- Récompenses obtenues
    xp_earned INTEGER DEFAULT 0,
    social_points_earned INTEGER DEFAULT 0,
    badges_earned UUID[],
    
    -- Feedback
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(event_id, user_id)
);

-- Table de l'impact social collectif
CREATE TABLE social_impact (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Type d'impact
    impact_type VARCHAR(30) NOT NULL CHECK (impact_type IN ('donation', 'volunteer_hours', 'environmental', 'education')),
    
    -- Détails
    title VARCHAR(255) NOT NULL,
    description TEXT,
    total_points_required INTEGER NOT NULL,
    current_points INTEGER DEFAULT 0,
    
    -- Partenariat
    partner_name VARCHAR(255),
    partner_logo_url TEXT,
    
    -- Progression
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Métadonnées
    start_date DATE NOT NULL,
    end_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- CHALLENGES ÉTENDUS
-- ===============================================

-- Table des types de challenges
CREATE TABLE challenge_types (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'meditation', 'quiz', 'exercise', 'habit', 'irl', 'team'
    
    -- Configuration par défaut
    default_config JSONB DEFAULT '{}',
    difficulty_levels JSONB DEFAULT '[]',
    
    -- Métadonnées
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des challenges disponibles ÉTENDUS
CREATE TABLE challenges (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL, -- NULL = global, sinon spécifique à l'organisation
    type_id UUID REFERENCES challenge_types(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructions TEXT,
    
    -- Configuration
    difficulty INTEGER DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    estimated_duration INTEGER, -- minutes
    xp_reward INTEGER DEFAULT 0,
    league_points_reward INTEGER DEFAULT 0,
    
    -- Contenu du challenge
    content JSONB DEFAULT '{}',
    
    -- Conditions de déblocage
    unlock_level INTEGER DEFAULT 1,
    required_badges UUID[],
    required_league VARCHAR(20),
    
    -- Récurrence
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern VARCHAR(20), -- 'daily', 'weekly', 'monthly'
    
    -- Équipe/Social
    is_team_challenge BOOLEAN DEFAULT false,
    min_team_size INTEGER DEFAULT 1,
    max_team_size INTEGER DEFAULT 10,
    
    -- État
    is_active BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des défis utilisateur ÉTENDUS
CREATE TABLE user_challenges (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE NOT NULL,
    
    -- Équipe (si challenge d'équipe)
    team_id UUID, -- référence vers une équipe temporaire
    team_name VARCHAR(255),
    
    -- État
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'failed', 'skipped')),
    
    -- Progression
    progress JSONB DEFAULT '{}',
    score INTEGER DEFAULT 0,
    completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Timing
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Récompenses
    xp_earned INTEGER DEFAULT 0,
    league_points_earned INTEGER DEFAULT 0,
    badges_earned UUID[],
    
    -- Métadonnées
    assigned_by VARCHAR(20) DEFAULT 'system' CHECK (assigned_by IN ('system', 'ai_coach', 'organization', 'friend')),
    difficulty_completed INTEGER, -- difficulté à laquelle il a été complété
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- SYSTÈME DE POINTS PLAFONNÉS
-- ===============================================

-- Table pour tracker les points quotidiens (anti-triche)
CREATE TABLE daily_points_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    
    -- Points par source (avec plafonds)
    focus_points INTEGER DEFAULT 0,
    focus_points_limit INTEGER DEFAULT 100,
    
    challenge_points INTEGER DEFAULT 0,
    challenge_points_limit INTEGER DEFAULT 50,
    
    social_points INTEGER DEFAULT 0,
    social_points_limit INTEGER DEFAULT 30,
    
    wellness_points INTEGER DEFAULT 0,
    wellness_points_limit INTEGER DEFAULT 25,
    
    irl_points INTEGER DEFAULT 0,
    irl_points_limit INTEGER DEFAULT 75,
    
    -- Total
    total_points INTEGER DEFAULT 0,
    daily_limit INTEGER DEFAULT 250,
    
    -- Validation serveur
    server_validated BOOLEAN DEFAULT false,
    validation_hash VARCHAR(255), -- hash pour vérifier intégrité
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

-- ===============================================
-- ORGANISATIONS - ANALYTICS ET REPORTING
-- ===============================================

-- Table des snapshots de reporting organisation (pré-calculés)
CREATE TABLE organization_report_snapshots (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
    
    -- Période
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'quarterly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Métriques agrégées (AUCUNE donnée individuelle)
    total_active_users INTEGER DEFAULT 0,
    total_focus_hours INTEGER DEFAULT 0, -- heures cumulées de toute l'organisation
    total_challenges_completed INTEGER DEFAULT 0,
    total_social_points INTEGER DEFAULT 0,
    
    -- Bien-être collectif
    average_focus_score DECIMAL(5,2) DEFAULT 0.0,
    average_league_level DECIMAL(3,1) DEFAULT 1.0,
    
    -- Engagement
    daily_active_users_avg INTEGER DEFAULT 0,
    challenge_participation_rate DECIMAL(5,2) DEFAULT 0.0,
    
    -- Impact social
    total_irl_events INTEGER DEFAULT 0,
    total_irl_participants INTEGER DEFAULT 0,
    social_impact_progress DECIMAL(5,2) DEFAULT 0.0,
    
    -- Métadonnées
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(organization_id, period_type, period_start)
);

-- ===============================================
-- TABLES EXISTANTES ADAPTÉES
-- ===============================================

-- Table des objectifs utilisateur
CREATE TABLE user_goals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    goal_type VARCHAR(30) NOT NULL CHECK (goal_type IN ('screen_time_reduction', 'bedtime', 'focus_sessions', 'app_specific', 'wellness', 'social_engagement')),
    
    -- Configuration objectif
    target_value INTEGER,
    current_value INTEGER DEFAULT 0,
    target_apps TEXT[],
    
    -- Planning
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    days_of_week INTEGER[] DEFAULT ARRAY[1,2,3,4,5,6,7],
    
    -- État
    is_active BOOLEAN DEFAULT true,
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Récompenses liées
    xp_reward_per_milestone INTEGER DEFAULT 10,
    league_points_reward INTEGER DEFAULT 5,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des catégories d'applications
CREATE TABLE app_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    color VARCHAR(7),
    
    -- Risque addictif
    default_risk_level INTEGER DEFAULT 1 CHECK (default_risk_level BETWEEN 1 AND 5),
    
    -- Métadonnées
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des applications
CREATE TABLE applications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    package_name VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES app_categories(id),
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'both')),
    icon_url TEXT,
    
    -- Configuration de blocage
    is_blockable BOOLEAN DEFAULT true,
    risk_level INTEGER DEFAULT 1 CHECK (risk_level BETWEEN 1 AND 5),
    default_challenge_on_open VARCHAR(50), -- type de challenge par défaut si ouverture bloquée
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des règles de blocage utilisateur
CREATE TABLE blocking_rules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Configuration
    rule_type VARCHAR(20) DEFAULT 'app_specific' CHECK (rule_type IN ('app_specific', 'category', 'time_based', 'location_based', 'context_based')),
    blocked_apps TEXT[],
    blocked_categories UUID[],
    
    -- Plages horaires
    time_slots JSONB DEFAULT '[]',
    
    -- Mode Nuit
    bedtime_start TIME,
    bedtime_end TIME,
    bedtime_whitelist TEXT[],
    
    -- Mode Hardcore
    hardcore_enabled BOOLEAN DEFAULT false,
    hardcore_challenge_required BOOLEAN DEFAULT true,
    hardcore_challenge_type VARCHAR(50), -- 'meditation', 'exercise', 'reflection'
    
    -- Prédictions IA
    ai_prediction_enabled BOOLEAN DEFAULT true,
    prediction_threshold DECIMAL(3,2) DEFAULT 0.7, -- seuil de confiance pour déclencher
    
    -- État
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions de focus ÉTENDUES
CREATE TABLE focus_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Configuration session
    planned_duration INTEGER NOT NULL,
    actual_duration INTEGER,
    session_type VARCHAR(20) DEFAULT 'focus' CHECK (session_type IN ('focus', 'break', 'long_break', 'deep_work', 'creative')),
    
    -- Défi lié
    challenge_id UUID REFERENCES challenges(id),
    
    -- État
    status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'paused', 'completed', 'cancelled')),
    
    -- Statistiques
    interruptions_count INTEGER DEFAULT 0,
    apps_blocked_during INTEGER DEFAULT 0,
    quality_score DECIMAL(3,2) DEFAULT 1.0, -- qualité de la session (0-1)
    
    -- Planning
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    paused_duration INTEGER DEFAULT 0,
    
    -- Récompenses
    xp_earned INTEGER DEFAULT 0,
    league_points_earned INTEGER DEFAULT 0,
    
    -- IA et contexte
    context_data JSONB DEFAULT '{}', -- mood, location, goals pour améliorer IA
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- AMIS ET SOCIAL (existant mais étendu)
-- ===============================================

-- Table des relations d'amitié
CREATE TABLE friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    addressee_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- État de la relation
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked', 'declined')),
    
    -- Statistiques d'amitié
    challenges_shared INTEGER DEFAULT 0,
    mutual_encouragements INTEGER DEFAULT 0,
    irl_events_attended_together INTEGER DEFAULT 0,
    
    -- Timing
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    
    -- Contraintes
    UNIQUE(requester_id, addressee_id),
    CHECK(requester_id != addressee_id)
);

-- ===============================================
-- IA ET PRÉDICTIONS
-- ===============================================

-- Table des sessions de coaching IA
CREATE TABLE ai_coaching_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Session
    session_type VARCHAR(30) DEFAULT 'chat' CHECK (session_type IN ('chat', 'prediction', 'intervention', 'check_in', 'motivation')),
    
    -- Contexte et conversation
    user_input TEXT,
    ai_response TEXT,
    conversation_context JSONB DEFAULT '{}',
    
    -- Prédiction si applicable
    prediction_confidence DECIMAL(3,2),
    predicted_behavior VARCHAR(50),
    intervention_triggered BOOLEAN DEFAULT false,
    
    -- Feedback utilisateur
    user_feedback INTEGER CHECK (user_feedback BETWEEN 1 AND 5),
    was_helpful BOOLEAN,
    
    -- Métadonnées IA
    model_version VARCHAR(50),
    response_time_ms INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des prédictions IA
CREATE TABLE ai_predictions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Prédiction
    prediction_type VARCHAR(30) NOT NULL CHECK (prediction_type IN ('usage_risk', 'bedtime_adherence', 'challenge_success', 'mood_decline', 'productivity_dip')),
    risk_score DECIMAL(3,2) NOT NULL,
    confidence DECIMAL(3,2) NOT NULL,
    
    -- Contexte et features
    context_features JSONB NOT NULL,
    time_window_hours INTEGER DEFAULT 2, -- prédiction pour les X prochaines heures
    
    -- Actions suggérées
    suggested_interventions JSONB DEFAULT '[]',
    intervention_applied VARCHAR(50),
    
    -- Résultat réel (pour améliorer le modèle)
    actual_outcome BOOLEAN,
    prediction_accuracy DECIMAL(3,2),
    
    -- Timing
    predicted_for TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- STATISTIQUES ET NOTIFICATIONS
-- ===============================================

-- Table des statistiques quotidiennes
CREATE TABLE daily_stats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    
    -- Temps d'écran
    total_screen_time INTEGER DEFAULT 0,
    app_usage JSONB DEFAULT '{}',
    
    -- Blocage et focus
    apps_blocked INTEGER DEFAULT 0,
    blocking_attempts INTEGER DEFAULT 0,
    focus_sessions INTEGER DEFAULT 0,
    total_focus_time INTEGER DEFAULT 0,
    focus_quality_avg DECIMAL(3,2) DEFAULT 0.0,
    
    -- Gamification
    xp_earned INTEGER DEFAULT 0,
    league_points_earned INTEGER DEFAULT 0,
    challenges_completed INTEGER DEFAULT 0,
    badges_earned INTEGER DEFAULT 0,
    
    -- Social et bien-être
    social_interactions INTEGER DEFAULT 0,
    irl_events_attended INTEGER DEFAULT 0,
    wellness_activities INTEGER DEFAULT 0,
    
    -- Sommeil (si disponible)
    estimated_bedtime TIME,
    estimated_sleep_duration INTEGER,
    bedtime_goal_met BOOLEAN,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

-- Table des notifications ÉTENDUES
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Contenu
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN ('challenge', 'achievement', 'reminder', 'social', 'system', 'prediction', 'coaching', 'irl_event')),
    
    -- Personnalisation
    tone VARCHAR(20) DEFAULT 'friendly', -- selon les préférences utilisateur
    urgency VARCHAR(10) DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high', 'urgent')),
    
    -- Données et actions
    action_data JSONB DEFAULT '{}',
    deep_link TEXT, -- lien vers une fonctionnalité spécifique
    
    -- Gamification
    contains_reward BOOLEAN DEFAULT false,
    xp_reward INTEGER DEFAULT 0,
    
    -- État
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    is_interactive BOOLEAN DEFAULT false, -- notification avec boutons d'action
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- INDICES POUR PERFORMANCE
-- ===============================================

-- Indices organisations
CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organization_plans_stripe ON organization_plans(stripe_customer_id, stripe_subscription_id);

-- Indices utilisateurs
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_organization ON profiles(organization_id, organization_role);
CREATE INDEX idx_profiles_league ON profiles(league, league_points);
CREATE INDEX idx_profiles_subscription ON profiles(subscription_tier, subscription_expires_at);

-- Indices gamification
CREATE INDEX idx_league_rankings_season ON league_rankings(season_id, league_id, points DESC);
CREATE INDEX idx_user_challenges_status ON user_challenges(user_id, status, expires_at);
CREATE INDEX idx_daily_points_user_date ON daily_points_tracking(user_id, date);

-- Indices events IRL (corrigés pour Supabase)
CREATE INDEX idx_irl_events_organization ON irl_events(organization_id, starts_at);
CREATE INDEX idx_irl_events_location ON irl_events(latitude, longitude); -- Index B-tree simple
CREATE INDEX idx_irl_participations_user ON irl_event_participations(user_id, status);

-- Indices statistiques et IA
CREATE INDEX idx_daily_stats_user_date ON daily_stats(user_id, date DESC);
CREATE INDEX idx_ai_predictions_user ON ai_predictions(user_id, prediction_type, predicted_for);
CREATE INDEX idx_focus_sessions_user_status ON focus_sessions(user_id, status, started_at DESC);

-- Indices reporting organisation
CREATE INDEX idx_org_reports_period ON organization_report_snapshots(organization_id, period_type, period_start);

-- ===============================================
-- TRIGGERS POUR MISE À JOUR AUTOMATIQUE
-- ===============================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Application des triggers
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organization_plans_updated_at BEFORE UPDATE ON organization_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_goals_updated_at BEFORE UPDATE ON user_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blocking_rules_updated_at BEFORE UPDATE ON blocking_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_focus_sessions_updated_at BEFORE UPDATE ON focus_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- FONCTIONS UTILITAIRES CORRIGÉES
-- ===============================================

-- Fonction pour calculer le niveau basé sur l'XP
CREATE OR REPLACE FUNCTION calculate_level(total_xp_param INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN FLOOR(SQRT(total_xp_param / 100.0)) + 1;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour déterminer la ligue basée sur les points
CREATE OR REPLACE FUNCTION calculate_league(league_points_param INTEGER)
RETURNS VARCHAR AS $$
BEGIN
    CASE 
        WHEN league_points_param >= 10000 THEN RETURN 'legendary';
        WHEN league_points_param >= 5000 THEN RETURN 'diamond';
        WHEN league_points_param >= 2500 THEN RETURN 'platinum';
        WHEN league_points_param >= 1000 THEN RETURN 'gold';
        WHEN league_points_param >= 300 THEN RETURN 'silver';
        ELSE RETURN 'bronze';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier les limites de points quotidiennes (corrigée)
CREATE OR REPLACE FUNCTION check_daily_points_limit(user_id_param UUID, points_source VARCHAR, points_to_add INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    current_tracking RECORD;
    new_points INTEGER;
BEGIN
    -- Récupérer le tracking du jour
    SELECT * INTO current_tracking 
    FROM daily_points_tracking 
    WHERE user_id = user_id_param 
    AND date = CURRENT_DATE;
    
    -- Si pas de record, créer
    IF current_tracking IS NULL THEN
        INSERT INTO daily_points_tracking (user_id, date) 
        VALUES (user_id_param, CURRENT_DATE);
        RETURN true;
    END IF;
    
    -- Vérifier selon la source
    CASE points_source
        WHEN 'focus' THEN 
            new_points := current_tracking.focus_points + points_to_add;
            RETURN new_points <= current_tracking.focus_points_limit;
        WHEN 'challenge' THEN 
            new_points := current_tracking.challenge_points + points_to_add;
            RETURN new_points <= current_tracking.challenge_points_limit;
        WHEN 'social' THEN 
            new_points := current_tracking.social_points + points_to_add;
            RETURN new_points <= current_tracking.social_points_limit;
        WHEN 'wellness' THEN 
            new_points := current_tracking.wellness_points + points_to_add;
            RETURN new_points <= current_tracking.wellness_points_limit;
        WHEN 'irl' THEN 
            new_points := current_tracking.irl_points + points_to_add;
            RETURN new_points <= current_tracking.irl_points_limit;
        ELSE 
            RETURN false;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Fonction utilitaire pour calculer la distance géographique sans extensions
CREATE OR REPLACE FUNCTION calculate_distance_km(lat1 DECIMAL, lon1 DECIMAL, lat2 DECIMAL, lon2 DECIMAL)
RETURNS DECIMAL AS $$
DECLARE
    earth_radius DECIMAL := 6371.0; -- rayon de la Terre en km
    dLat DECIMAL;
    dLon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    -- Conversion en radians
    dLat := RADIANS(lat2 - lat1);
    dLon := RADIANS(lon2 - lon1);
    
    -- Formule haversine
    a := SIN(dLat/2) * SIN(dLat/2) + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * SIN(dLon/2) * SIN(dLon/2);
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    
    RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- RLS (ROW LEVEL SECURITY) POUR SUPABASE
-- ===============================================

-- Activation RLS sur toutes les tables sensibles
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocking_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_coaching_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE irl_event_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_points_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_report_snapshots ENABLE ROW LEVEL SECURITY;

-- Politiques de base pour utilisateurs
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can manage own data" ON user_goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own blocking rules" ON blocking_rules FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own focus sessions" ON focus_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own challenges" ON user_challenges FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view own stats" ON daily_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own AI sessions" ON ai_coaching_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own points tracking" ON daily_points_tracking FOR ALL USING (auth.uid() = user_id);

-- Politiques pour organisations
CREATE POLICY "Organization admins can manage their org" ON organizations 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND organization_id = organizations.id 
            AND organization_role IN ('admin', 'owner')
        )
    );

CREATE POLICY "Organization members can view their org reports" ON organization_report_snapshots 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND organization_id = organization_report_snapshots.organization_id
        )
    );

-- Politiques pour événements IRL
CREATE POLICY "Users can view public IRL events" ON irl_events FOR SELECT USING (is_public = true);
CREATE POLICY "Organization members can view their org events" ON irl_events 
    FOR SELECT USING (
        organization_id IS NULL OR 
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND organization_id = irl_events.organization_id
        )
    );

CREATE POLICY "Users can manage their IRL participations" ON irl_event_participations 
    FOR ALL USING (auth.uid() = user_id);

-- Tables publiques en lecture
ALTER TABLE app_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE trophies ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranking_seasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access" ON app_categories FOR SELECT USING (true);
CREATE POLICY "Public read access" ON applications FOR SELECT USING (true);
CREATE POLICY "Public read access" ON badges FOR SELECT USING (true);
CREATE POLICY "Public read access" ON trophies FOR SELECT USING (true);
CREATE POLICY "Public read access" ON challenges FOR SELECT USING (true);
CREATE POLICY "Public read access" ON challenge_types FOR SELECT USING (true);
CREATE POLICY "Public read access" ON leagues FOR SELECT USING (true);
CREATE POLICY "Public read access" ON ranking_seasons FOR SELECT USING (true);

-- ===============================================
-- DONNÉES D'EXEMPLE (SEED DATA)
-- ===============================================

-- Ligues
INSERT INTO leagues (name, slug, level, min_points, max_points, color) VALUES
('Bronze', 'bronze', 1, 0, 299, '#CD7F32'),
('Argent', 'silver', 2, 300, 999, '#C0C0C0'),
('Or', 'gold', 3, 1000, 2499, '#FFD700'),
('Platine', 'platinum', 4, 2500, 4999, '#E5E4E2'),
('Diamant', 'diamond', 5, 5000, 9999, '#B9F2FF'),
('Légendaire', 'legendary', 6, 10000, NULL, '#FF6B35');

-- Catégories d'applications
INSERT INTO app_categories (name, slug, description, color, default_risk_level) VALUES
('Réseaux Sociaux', 'social', 'Applications de réseaux sociaux', '#FF6B6B', 5),
('Divertissement', 'entertainment', 'Streaming, vidéos, jeux', '#4ECDC4', 4),
('Productivité', 'productivity', 'Outils de travail et productivité', '#45B7D1', 1),
('Communication', 'communication', 'Messagerie et communication', '#96CEB4', 2),
('Jeux', 'games', 'Jeux mobiles', '#FFEAA7', 5),
('Shopping', 'shopping', 'Applications de shopping', '#DDA0DD', 3),
('Éducation', 'education', 'Apps d''apprentissage et éducation', '#98FB98', 1),
('Sport & Santé', 'health', 'Fitness, méditation, santé', '#FFA07A', 1);

-- Applications populaires avec niveau de risque
INSERT INTO applications (package_name, display_name, category_id, platform, risk_level, default_challenge_on_open) VALUES
('com.instagram.android', 'Instagram', (SELECT id FROM app_categories WHERE slug = 'social'), 'android', 5, 'reflection'),
('com.facebook.katana', 'Facebook', (SELECT id FROM app_categories WHERE slug = 'social'), 'android', 4, 'breathing'),
('com.zhiliaoapp.musically', 'TikTok', (SELECT id FROM app_categories WHERE slug = 'social'), 'android', 5, 'meditation'),
('com.snapchat.android', 'Snapchat', (SELECT id FROM app_categories WHERE slug = 'social'), 'android', 4, 'reflection'),
('com.netflix.mediaclient', 'Netflix', (SELECT id FROM app_categories WHERE slug = 'entertainment'), 'android', 3, 'breathing'),
('com.google.android.youtube', 'YouTube', (SELECT id FROM app_categories WHERE slug = 'entertainment'), 'android', 4, 'reflection');

-- Types de challenges étendus
INSERT INTO challenge_types (name, slug, description, category) VALUES
('Méditation', 'meditation', 'Séances de méditation guidée', 'meditation'),
('Quiz Bien-être', 'wellness_quiz', 'Questions sur les habitudes saines', 'quiz'),
('Exercice Physique', 'exercise', 'Petits exercices physiques', 'exercise'),
('Respiration', 'breathing', 'Exercices de respiration', 'meditation'),
('Réflexion', 'reflection', 'Questions de développement personnel', 'habit'),
('Événement IRL', 'irl_event', 'Participation à des événements réels', 'irl'),
('Défi d''Équipe', 'team_challenge', 'Défis collectifs entre collègues/amis', 'team');

-- Badges avec rareté étendue
INSERT INTO badges (name, slug, description, category, rarity, xp_reward, league_points_reward, unlock_conditions) VALUES
('Premier Pas', 'first_step', 'Complétez votre premier challenge', 'challenges', 'common', 10, 5, '{"type": "challenges_completed", "value": 1}'),
('Série de 3', 'streak_3', 'Maintenez une série de 3 jours', 'streak', 'common', 25, 10, '{"type": "streak", "value": 3}'),
('Série de 7', 'streak_7', 'Maintenez une série de 7 jours', 'streak', 'rare', 50, 25, '{"type": "streak", "value": 7}'),
('Maître du Focus', 'focus_master', 'Complétez 50 sessions de focus', 'focus', 'epic', 150, 75, '{"type": "focus_sessions", "value": 50}'),
('Résistant Légendaire', 'legendary_resistant', 'Bloquez 1000 tentatives d''ouverture d''apps', 'blocking', 'legendary', 500, 250, '{"type": "apps_blocked", "value": 1000}'),
('Champion Social', 'social_champion', 'Participez à 10 événements IRL', 'social', 'epic', 200, 100, '{"type": "irl_events_attended", "value": 10}'),
('Mentor Bienveillant', 'kind_mentor', 'Aidez 5 nouveaux utilisateurs', 'social', 'rare', 100, 50, '{"type": "users_helped", "value": 5}'),
('Avatar Mythique', 'mythical_avatar', 'Atteignez le niveau 50 d''avatar', 'progression', 'mythical', 1000, 500, '{"type": "avatar_level", "value": 50}');

-- Challenges avec récompenses étendues
INSERT INTO challenges (type_id, title, description, difficulty, estimated_duration, xp_reward, league_points_reward, content, is_team_challenge) VALUES
((SELECT id FROM challenge_types WHERE slug = 'meditation'), 'Méditation Matinale', 'Commencez votre journée par 5 minutes de méditation', 1, 5, 15, 8, '{"audio_url": "", "instructions": "Asseyez-vous confortablement et concentrez-vous sur votre respiration"}', false),
((SELECT id FROM challenge_types WHERE slug = 'breathing'), 'Respiration 4-7-8', 'Technique de respiration relaxante', 1, 4, 10, 5, '{"pattern": [4, 7, 8], "cycles": 4}', false),
((SELECT id FROM challenge_types WHERE slug = 'reflection'), 'Réflexion du Soir', 'Pourquoi ai-je voulu ouvrir cette app ?', 2, 3, 12, 6, '{"questions": ["Que cherchais-je vraiment ?", "Comment me sens-je maintenant ?"]}', false),
((SELECT id FROM challenge_types WHERE slug = 'team_challenge'), 'Équipe sans Réseaux Sociaux', 'Votre équipe évite les réseaux sociaux pendant 24h', 3, 1440, 50, 25, '{"team_goal": "no_social_media", "duration_hours": 24}', true),
((SELECT id FROM challenge_types WHERE slug = 'irl_event'), 'Méditation Groupe', 'Rejoignez une session de méditation collective', 2, 60, 30, 15, '{"event_type": "meditation", "min_participants": 3}', false);

-- Trophées prestigieux
INSERT INTO trophies (name, slug, description, tier, xp_reward, league_points_reward, grants_title, unlock_conditions) VALUES
('Gardien du Sommeil', 'sleep_guardian', 'Respectez votre heure de coucher pendant 30 jours', 'gold', 300, 150, 'Gardien du Sommeil', '{"type": "bedtime_respected", "value": 30, "consecutive": true}'),
('Maître Zen', 'zen_master', 'Atteignez 1000 minutes de méditation', 'platinum', 500, 250, 'Maître Zen', '{"type": "meditation_minutes", "value": 1000}'),
('Leader Communautaire', 'community_leader', 'Organisez 10 événements IRL réussis', 'diamond', 750, 375, 'Leader Communautaire', '{"type": "events_organized", "value": 10, "success_rate": 0.8}'),
('Transformateur de Vies', 'life_transformer', 'Mentorez 25 utilisateurs avec succès', 'diamond', 1000, 500, 'Transformateur de Vies', '{"type": "successful_mentorships", "value": 25}');

-- ===============================================
-- COMMENTAIRES DE DOCUMENTATION
-- ===============================================

COMMENT ON TABLE organizations IS 'Organisations/entreprises avec facturation centralisée';
COMMENT ON TABLE organization_plans IS 'Plans d''abonnement et facturation Stripe pour organisations';
COMMENT ON TABLE profiles IS 'Profils utilisateurs avec gamification avancée et support multi-tenant';
COMMENT ON TABLE leagues IS 'Système de ligues (Bronze, Argent, Or, etc.) pour la compétition';
COMMENT ON TABLE irl_events IS 'Événements dans la vraie vie (maraudes, sport, méditation) avec validation QR/GPS';
COMMENT ON TABLE daily_points_tracking IS 'Système anti-triche avec plafonds quotidiens de points par source';
COMMENT ON TABLE ai_predictions IS 'Prédictions IA pour intervention proactive sur les moments de faiblesse';
COMMENT ON TABLE organization_report_snapshots IS 'Analytics agrégées pour entreprises (RGPD-compliant)';
COMMENT ON TABLE social_impact IS 'Tracking de l''impact social collectif (dons, bénévolat)';

-- ===============================================
-- FIN DU SCRIPT DECONNECT MULTI-TENANT CORRIGÉ
-- ===============================================

-- Script de validation (à exécuter pour tester)
/*
SELECT 'Schema created successfully!' as result;

-- Test des fonctions
SELECT calculate_level(250) as level_test; -- Devrait retourner 2
SELECT calculate_league(1500) as league_test; -- Devrait retourner 'gold'
SELECT calculate_distance_km(48.8566, 2.3522, 48.8606, 2.3376) as distance_test; -- Distance Paris
*/