enum NotionBlockType { paragraph, heading1, heading2, heading3, bulletedListItem, numberedListItem, toDo, quote, image, unknown }

class NotionBlock {
  final String id;
  final NotionBlockType type;
  final String text;
  final bool checked;

  NotionBlock({required this.id, required this.type, required this.text, this.checked = false});

  factory NotionBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    String text = '';
    bool checked = false;

    NotionBlockType type = switch (typeStr) {
      'paragraph' => NotionBlockType.paragraph,
      'heading_1' => NotionBlockType.heading1,
      'heading_2' => NotionBlockType.heading2,
      'heading_3' => NotionBlockType.heading3,
      'bulleted_list_item' => NotionBlockType.bulletedListItem,
      'numbered_list_item' => NotionBlockType.numberedListItem,
      'to_do' => NotionBlockType.toDo,
      'quote' => NotionBlockType.quote,
      'image' => NotionBlockType.image,
      _ => NotionBlockType.unknown,
    };

    final blockData = json[typeStr] as Map<String, dynamic>?;
    if (blockData != null) {
      final richText = blockData['rich_text'] as List?;
      if (richText != null) {
        text = richText.map((t) => t['plain_text'] ?? '').join('');
      }
      if (type == NotionBlockType.toDo) {
        checked = blockData['checked'] as bool? ?? false;
      }
    }

    return NotionBlock(id: json['id'] as String, type: type, text: text, checked: checked);
  }
}

class NotionPage {
  final String id;
  final String title;
  final DateTime lastEdited;
  final List<NotionBlock> blocks;

  NotionPage({required this.id, required this.title, required this.lastEdited, this.blocks = const []});

  NotionPage copyWith({List<NotionBlock>? blocks}) =>
      NotionPage(id: id, title: title, lastEdited: lastEdited, blocks: blocks ?? this.blocks);

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    String title = 'Sans titre';
    final props = json['properties'] as Map<String, dynamic>?;
    if (props != null) {
      for (final key in ['title', 'Title', 'Name', 'name']) {
        final prop = props[key] as Map<String, dynamic>?;
        if (prop != null && prop['type'] == 'title') {
          final arr = prop['title'] as List?;
          if (arr != null && arr.isNotEmpty) {
            title = arr.map((t) => t['plain_text'] ?? '').join('');
            break;
          }
        }
      }
    }

    return NotionPage(
      id: json['id'] as String,
      title: title.isEmpty ? 'Sans titre' : title,
      lastEdited: DateTime.parse(json['last_edited_time'] as String),
    );
  }
}
