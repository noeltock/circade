#!/usr/bin/env bash
# Static WordPress semantic inventory (repo only, no site): hooks, registrations,
# storage, cron, assets, capabilities, multisite switches. Counts + top offenders.
# Usage: wp-inventory.sh [paths...]   (respects .gitignore; excludes vendor/node_modules/tests)
set -u; . "$(dirname "$0")/lib.sh"
command -v rg >/dev/null || { echo "rg required" >&2; exit 2; }
P=("${@:-.}")
T=(-g '!**/tests/**' -g '!**/test/**' -g '!**/__tests__/**' -g '!**/spec/**' -g '!**/fixtures/**' -g '!**/__snapshots__/**' -g '!**/*Test.php' -g '!**/*_test.php' -g '!**/*.test.*' -g '!**/*.spec.*')
G=(-g '*.php' -g '!vendor' -g '!node_modules' -g '!dist' -g '!build' -g '!**/generated/**' "${T[@]}")
rt=$(rg --files "${G[@]}" "${P[@]}" 2>/dev/null | wc -l | tr -d ' '); all=$(rg --files -g '*.php' -g '!vendor' -g '!node_modules' -g '!dist' -g '!build' "${P[@]}" 2>/dev/null | wc -l | tr -d ' ')
echo "scope: paths ${P[*]} · runtime php files $rt · test/fixture/generated files excluded $((all-rt)) · vendor/node_modules/dist/build excluded"

c() { rg -c "${G[@]}" -e "$1" "${P[@]}" 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}'; }
top() { rg -o --no-filename "${G[@]}" -e "$1" -r '$2' "${P[@]}" 2>/dev/null | sort | uniq -c | sort -rn | head -"${2:-8}" | awk '{printf "    %s x%s\n",$2,$1}'; }
echo "hooks: listeners add_action=$(c 'add_action\(') add_filter=$(c 'add_filter\(') | emitters do_action=$(c 'do_action\(') apply_filters=$(c 'apply_filters\(') | removals=$(c 'remove_(action|filter)\(')"
echo "  most-listened hooks:"; top "add_(action|filter)\(\s*['\"]([a-zA-Z0-9_\-/{}\$]+)['\"]" 8
echo "  dynamic hook names (interpolated): $(c "(add|do|remove)_(action|filter)\(\s*[\"'][^\"']*\\\$")"
echo "registrations: post_types=$(c 'register_post_type\(') taxonomies=$(c 'register_taxonomy\(') rest_routes=$(c 'register_rest_route\(') blocks=$(c 'register_block_type') shortcodes=$(c 'add_shortcode\(') cli=$(c 'WP_CLI::add_command') abilities=$(c 'wp_register_ability|register_ability\(') ajax=$(c "add_action\(\s*['\"]wp_ajax_")"
echo "  rest routes without permission_callback: $(rg -U "${G[@]}" -e 'register_rest_route\((?:(?!permission_callback)[^;])*\);' "${P[@]}" 2>/dev/null | rg -c 'register_rest_route' || echo 0)"
echo "storage: options=$(c 'get_option\(') site_options=$(c 'get_site_option\(') update_option=$(c 'update_option\(') transients=$(c 'set_transient\(') site_transients=$(c 'set_site_transient\(') postmeta=$(c '(get|update|add)_post_meta\(') cache_set=$(c 'wp_cache_set\(') custom_tables=$(c 'CREATE TABLE|dbDelta\(') raw_sql=$(c '\$wpdb->(query|get_results|get_var|get_row|get_col)\(')"
echo "  distinct option keys:"; top "(get|update|add|delete)_option\(\s*['\"]([a-zA-Z0-9_\-]+)['\"]" 8
echo "  autoload=false on update/add_option: $(c "(update|add)_option\([^;]*(false|'no'|\"no\")\s*\)")  (of $(c '(update|add)_option\('))"
echo "cron: schedule=$(c 'wp_schedule_(single_)?event\(') listeners=$(c "add_action\(\s*['\"][a-z0-9_]*cron") unschedule=$(c 'wp_(clear_scheduled_hook|unschedule_event)\(') next_scheduled_guards=$(c 'wp_next_scheduled\(')"
echo "assets: enqueue_script=$(c 'wp_enqueue_script\(') enqueue_style=$(c 'wp_enqueue_style\(') register=$(c 'wp_register_(script|style)\(') localize=$(c 'wp_(localize|add_inline)_script\(')"
echo "authz: current_user_can=$(c 'current_user_can\(') nonces_create=$(c 'wp_(create_nonce|nonce_field)\(') nonces_verify=$(c '(wp_verify_nonce|check_admin_referer|check_ajax_referer)\(') add_cap=$(c '->add_cap\(') add_role=$(c 'add_role\(')"
echo "multisite: switch_to_blog=$(c 'switch_to_blog\(') restore=$(c 'restore_current_blog\(') get_sites=$(c 'get_sites\(') is_multisite=$(c 'is_multisite\(')"
echo "remote http: wp_remote=$(c 'wp_remote_(get|post|request)\(') curl=$(c 'curl_init\(') file_get_contents_url=$(c "file_get_contents\(\s*['\"]https?:")"
echo "unbounded queries: posts_per_page=-1 $(c "posts_per_page['\"]?\s*=>\s*-1") | numberposts=-1 $(c "numberposts['\"]?\s*=>\s*-1") | no_found_rows missing on WP_Query: $(( $(c 'new WP_Query\(') - $(c 'no_found_rows') ))"
echo "lifecycle: activation=$(c 'register_activation_hook\(') deactivation=$(c 'register_deactivation_hook\(') uninstall=$(c 'register_uninstall_hook\(|uninstall\.php') flush_rewrite=$(c 'flush_rewrite_rules\(')"
