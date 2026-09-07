# WordPress
Activates when `scripts/detect-wp.sh` exits 0. Static only: dynamic hook names are unresolved, so every path claim is "static-approximate".

## Inventory (`scripts/wp-inventory.sh <paths>`)
Hooks (listeners vs emitters, most-listened, dynamic names) · registrations (post types, taxonomies, REST routes and those without `permission_callback`, blocks, shortcodes, CLI, Abilities, AJAX) · storage (options vs site options, transients, meta, cache, raw `$wpdb`, tables, autoload share) · cron (schedule vs unschedule vs guards) · assets · caps and nonces · multisite (`switch_to_blog` vs `restore_current_blog`) · remote HTTP · unbounded queries · lifecycle hooks. Run it via `git archive` at the trend commits when a current is suspected: a registration or option-key count that only grows is WP surface growth.

## Findings it enables, strongest first
1. **Lifecycle absent**: no activation/deactivation/uninstall against N option writes and cron schedules; data and events outlive the plugin. Check the main plugin file, not only `inc/`.
2. **Cron balance**: schedules without unschedule or `wp_next_scheduled` guards. Compare hook and args before calling a pair a duplicate.
3. **Storage scope and autoload**: writes defaulting autoload matter only for request-time or frequently changing values; site vs network mixing when `is_multisite` appears.
4. **Registration scatter**: `rest_api_init` listened in 16 places is a locality finding; the count alone is not.
5. **Multisite balance**: `switch_to_blog` ≠ `restore_current_blog`, or early returns between them.
6. **Unbounded queries, remote HTTP, direct DB, nonces, escaping**: adopt `wp plugin check <path>` and VIPCS (`NoPaging`, `WPQueryParams`, `FetchingRemoteData`, `RemoteRequestTimeout`, `LowExpiryCacheTime`) plus WPCS (`DirectDatabaseQuery`, `NonceVerification`, `EscapeOutput`). Custom only: reachability from an `init`/`wp`/`template_redirect` listener chain, labelled static-approximate.
Report passes too: "27/27 REST routes have permission callbacks" is one cheap line.

Dead-code guards (`wp-refs.sh`, `php-parent-chain.sh`) are in tools.md. The idea generalises: every stack has an implicit application assembled through registrations, and the surface inventory is that idea as a lens artefact. Anything that needs a running site (runtime hook traces, plugin-conflict testing, performance budgets) is out of scope.
