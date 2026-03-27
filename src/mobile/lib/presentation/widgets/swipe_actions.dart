import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';

class SwipeAction {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  SwipeAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

class SwipeActionTile extends StatefulWidget {
  final Widget child;
  final SwipeAction? leftAction;
  final SwipeAction? rightAction;
  final VoidCallback? onDismissed;

  const SwipeActionTile({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.onDismissed,
  });

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;

  static const double _actionThreshold = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(
        widget.leftAction != null ? -_actionThreshold : 0,
        widget.rightAction != null ? _actionThreshold : 0,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _actionThreshold) {
      if (_dragExtent > 0 && widget.rightAction != null) {
        widget.rightAction!.onTap();
      } else if (_dragExtent < 0 && widget.leftAction != null) {
        widget.leftAction!.onTap();
      }
    }
    _resetPosition();
  }

  void _resetPosition() {
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragExtent / context.size!.width, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0).then((_) {
      setState(() => _dragExtent = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                if (widget.leftAction != null)
                  Expanded(
                    child: Container(
                      color: widget.leftAction!.color,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.leftAction!.icon, color: Colors.white),
                          const SizedBox(height: 4),
                          Text(
                            widget.leftAction!.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.rightAction != null)
                  Expanded(
                    child: Container(
                      color: widget.rightAction!.color,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.rightAction!.icon, color: Colors.white),
                          const SizedBox(height: 4),
                          Text(
                            widget.rightAction!.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _slideAnimation.value
                  : Offset(_dragExtent / MediaQuery.of(context).size.width, 0);
              return SlideTransition(
                position: AlwaysStoppedAnimation(offset),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

class SwipeableListTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SwipeableListTile({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeActionTile(
      leftAction: onDelete != null
          ? SwipeAction(
              icon: Icons.delete,
              color: AppTheme.accentRed,
              label: 'Eliminar',
              onTap: () {
                if (onDelete != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar'),
                      content: const Text('¿Estás seguro de eliminar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          child: const Text('Eliminar',
                              style: TextStyle(color: AppTheme.accentRed)),
                        ),
                      ],
                    ),
                  );
                }
              },
            )
          : null,
      rightAction: onEdit != null
          ? SwipeAction(
              icon: Icons.edit,
              color: AppTheme.accentBlue,
              label: 'Editar',
              onTap: () => onEdit!(),
            )
          : null,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
