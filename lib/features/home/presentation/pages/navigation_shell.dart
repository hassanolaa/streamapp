import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/home/presentation/pages/home_page.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;
  final List<FocusNode> _navFocusNodes = List.generate(6, (_) => FocusNode());

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'home'),
    _NavItem(icon: Icons.explore_rounded, label: 'browse'),
    _NavItem(icon: Icons.video_library_rounded, label: 'watch_list'),
    _NavItem(icon: Icons.download_rounded, label: 'downloads'),
    _NavItem(icon: Icons.settings_rounded, label: 'settings'),
    _NavItem(icon: Icons.help_rounded, label: 'help'),
  ];

  @override
  void dispose() {
    for (var node in _navFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onNavItemSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavigateUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavigateDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateUpIntent: CallbackAction<_NavigateUpIntent>(
            onInvoke: (_) {
              if (_selectedIndex > 0) {
                setState(() => _selectedIndex--);
                _navFocusNodes[_selectedIndex].requestFocus();
              }
              return null;
            },
          ),
          _NavigateDownIntent: CallbackAction<_NavigateDownIntent>(
            onInvoke: (_) {
              if (_selectedIndex < _navItems.length - 1) {
                setState(() => _selectedIndex++);
                _navFocusNodes[_selectedIndex].requestFocus();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          body: Row(
            children: [
              _buildSidebar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 40),
          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return Focus(
                  focusNode: _navFocusNodes[index],
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      _onNavItemSelected(index);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: _NavButton(
                    icon: item.icon,
                    label: item.label.tr(),
                    isSelected: isSelected,
                    onTap: () => _onNavItemSelected(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      default:
        return Center(
          child: Text(
            _navItems[_selectedIndex].label.tr(),
            style: Theme.of(context).textTheme.displayMedium,
          ),
        );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium!.color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigateUpIntent extends Intent {
  const _NavigateUpIntent();
}

class _NavigateDownIntent extends Intent {
  const _NavigateDownIntent();
}
