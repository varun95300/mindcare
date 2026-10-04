import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'ui.dart';

class NavItem {
  final IconData icon;
  final String label;
  final int? badge;
  const NavItem(this.icon, this.label, {this.badge});
}

/// Application frame: a sidebar on wide screens, a bottom bar on narrow
/// ones. Page content is centred and capped at [Breakpoints.contentMaxWidth].
class AppShell extends StatelessWidget {
  final String roleLabel;
  final String userName;
  final String? userEmail;
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final List<PopupMenuEntry<String>> menuExtras;
  final ValueChanged<String>? onMenuSelected;
  final Widget child;

  const AppShell({
    super.key,
    required this.roleLabel,
    required this.userName,
    this.userEmail,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.menuExtras = const [],
    this.onMenuSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    final content = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 40 : 16,
        vertical: wide ? 32 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: child,
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: MindCareTheme.background,
        body: Row(
          children: [
            _Sidebar(
              roleLabel: roleLabel,
              userName: userName,
              userEmail: userEmail,
              items: items,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              onLogout: onLogout,
              menuExtras: menuExtras,
              onMenuSelected: onMenuSelected,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const _Logo(compact: true),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: Avatar(userName, size: 32),
            onSelected: (v) {
              if (v == 'logout') {
                onLogout();
              } else {
                onMenuSelected?.call(v);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('$userName · $roleLabel'),
              ),
              ...menuExtras,
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
      bottomNavigationBar: items.length > 1
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              backgroundColor: MindCareTheme.surface,
              indicatorColor: MindCareTheme.primaryLight,
              destinations: [
                for (final i in items)
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: (i.badge ?? 0) > 0,
                      label: Text('${i.badge}'),
                      child: Icon(i.icon),
                    ),
                    label: i.label,
                  ),
              ],
            )
          : null,
    );
  }
}

class _Logo extends StatelessWidget {
  final bool compact;
  const _Logo({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 32 : 38,
          height: compact ? 32 : 38,
          decoration: BoxDecoration(
            gradient: MindCareTheme.primaryGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          'MindCare',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontSize: compact ? 18 : 20),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String roleLabel;
  final String userName;
  final String? userEmail;
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final List<PopupMenuEntry<String>> menuExtras;
  final ValueChanged<String>? onMenuSelected;

  const _Sidebar({
    required this.roleLabel,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.menuExtras,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: MindCareTheme.surface,
        border: Border(right: BorderSide(color: MindCareTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _Logo(),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              roleLabel.toUpperCase(),
              style: text.bodyMedium?.copyWith(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: MindCareTheme.textLight,
              ),
            ),
          ),
          for (int i = 0; i < items.length; i++)
            _NavTile(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            tooltip: 'Account',
            position: PopupMenuPosition.over,
            onSelected: (v) {
              if (v == 'logout') {
                onLogout();
              } else {
                onMenuSelected?.call(v);
              }
            },
            itemBuilder: (_) => [
              ...menuExtras,
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 10),
                  Text('Sign out'),
                ]),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Avatar(userName, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(fontSize: 14)),
                        Text(roleLabel,
                            style: text.bodyMedium?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.unfold_more,
                      size: 18, color: MindCareTheme.textLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? MindCareTheme.primaryDark : MindCareTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? MindCareTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if ((item.badge ?? 0) > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MindCareTheme.accent,
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusFull),
                    ),
                    child: Text(
                      '${item.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
