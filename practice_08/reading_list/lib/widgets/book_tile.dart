import 'package:flutter/material.dart';

import '../models/book.dart';

class BookTile extends StatelessWidget {
  const BookTile({
    super.key,
    required this.book,
    required this.onToggle,
    required this.onTap,
  });
  final Book book;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      book.title.isEmpty ? '?' : book.title.substring(0, 1),
                    ),
                  ),
                  if (!book.read)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.author} · ${book.pages} pp.',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: book.read,
                onChanged: (_) => onToggle(),
                semanticLabel:
                    'Mark ${book.title} as ${book.read ? 'unread' : 'read'}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
