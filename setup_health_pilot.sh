#!/bin/bash
# ============================================================
# health_pilot/ — Flutter Project Scaffold
# ANTIGRAVITY · Architecture v1.0
# Run from inside your cloned repo root:
#   chmod +x setup_health_pilot.sh && ./setup_health_pilot.sh
# ============================================================

set -e
ROOT="lib"

echo "🚀 Scaffolding health_pilot Flutter project..."

# ── Directory structure ──────────────────────────────────────
mkdir -p $ROOT/core
mkdir -p $ROOT/models
mkdir -p $ROOT/services
mkdir -p $ROOT/providers
mkdir -p $ROOT/screens/auth
mkdir -p $ROOT/screens/dashboards
mkdir -p $ROOT/screens/vitals
mkdir -p $ROOT/screens/ai
mkdir -p $ROOT/screens/records
mkdir -p $ROOT/screens/chat
mkdir -p $ROOT/widgets
mkdir -p assets/icons
mkdir -p assets/fonts

# ── Helper: create stub dart file ────────────────────────────
stub() {
  local path=$1
  local filename=$(basename "$path" .dart)
  local classname=$(echo "$filename" | sed 's/_\([a-z]\)/\U\1/g; s/^\([a-z]\)/\U\1/')
  if [ ! -f "$path" ]; then
    cat > "$path" <<EOF
// TODO: Implement $filename
// Sprint assignment: see architecture doc

EOF
    echo "  ✓ $path"
  else
    echo "  ⚠ Skipped (exists): $path"
  fi
}

echo ""
echo "📁 lib/ root"
stub $ROOT/router.dart

echo ""
echo "📁 core/"
stub $ROOT/core/constants.dart
stub $ROOT/core/supabase_client.dart
stub $ROOT/core/theme.dart

echo ""
echo "📁 models/"
stub $ROOT/models/user_model.dart
stub $ROOT/models/health_metric.dart
stub $ROOT/models/sos_alert.dart
stub $ROOT/models/message.dart
stub $ROOT/models/medical_record.dart

echo ""
echo "📁 services/"
stub $ROOT/services/auth_service.dart
stub $ROOT/services/profile_service.dart
stub $ROOT/services/watch_service.dart
stub $ROOT/services/sos_service.dart
stub $ROOT/services/notification_service.dart
stub $ROOT/services/gemini_service.dart
stub $ROOT/services/storage_service.dart
stub $ROOT/services/chat_service.dart

echo ""
echo "📁 providers/"
stub $ROOT/providers/auth_provider.dart
stub $ROOT/providers/health_provider.dart
stub $ROOT/providers/chat_provider.dart

echo ""
echo "📁 screens/auth/"
stub $ROOT/screens/auth/login_page.dart
stub $ROOT/screens/auth/signup_page.dart
stub $ROOT/screens/auth/pending_verification.dart

echo ""
echo "📁 screens/dashboards/"
stub $ROOT/screens/dashboards/patient_dashboard.dart
stub $ROOT/screens/dashboards/doctor_dashboard.dart

echo ""
echo "📁 screens/vitals/"
stub $ROOT/screens/vitals/vitals_screen.dart
stub $ROOT/screens/vitals/sos_screen.dart

echo ""
echo "📁 screens/ai/"
stub $ROOT/screens/ai/ai_assistant_screen.dart

echo ""
echo "📁 screens/records/"
stub $ROOT/screens/records/records_screen.dart
stub $ROOT/screens/records/records_viewer.dart

echo ""
echo "📁 screens/chat/"
stub $ROOT/screens/chat/patient_chat_screen.dart
stub $ROOT/screens/chat/doctor_inbox_screen.dart
stub $ROOT/screens/chat/chat_room_screen.dart
stub $ROOT/screens/chat/caregiver_screen.dart

echo ""
echo "📁 widgets/"
stub $ROOT/widgets/app_shell.dart
stub $ROOT/widgets/vitals_card.dart
stub $ROOT/widgets/sos_button.dart
stub $ROOT/widgets/message_bubble.dart
stub $ROOT/widgets/loading_shimmer.dart

# ── .env template ────────────────────────────────────────────
if [ ! -f ".env" ]; then
  cat > .env <<EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_KEY=your-gemini-api-key
EOF
  echo ""
  echo "📄 .env created (fill in your keys)"
else
  echo ""
  echo "⚠ .env already exists — skipped"
fi

# ── .gitignore additions ─────────────────────────────────────
if ! grep -q "\.env" .gitignore 2>/dev/null; then
  echo "" >> .gitignore
  echo "# Secrets" >> .gitignore
  echo ".env" >> .gitignore
  echo "  ✓ Added .env to .gitignore"
fi

# ── analysis_options.yaml ────────────────────────────────────
if [ ! -f "analysis_options.yaml" ]; then
  cat > analysis_options.yaml <<EOF
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_final_fields: true
EOF
  echo "  ✓ analysis_options.yaml created"
fi

echo ""
echo "✅ Done! health_pilot scaffold complete."
echo ""
echo "Next steps:"
echo "  1. Fill in .env with your Supabase + Gemini keys"
echo "  2. Run: flutter pub get"
echo "  3. Check pubspec.yaml — add: go_router, supabase_flutter, flutter_riverpod, google_generative_ai"
echo ""
