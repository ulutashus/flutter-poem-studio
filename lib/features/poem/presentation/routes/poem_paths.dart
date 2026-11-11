abstract final class PoemPaths {
  static const list = '/poems';
  static const detail = '/poems/:id';
  static const edit = '/poems/:id/edit';

  static String detailPath(String id) => _fill(detail, id);

  static String editPath(String id) => _fill(edit, id);

  static String _fill(String template, String id) =>
      template.replaceFirst(':id', Uri.encodeComponent(id));
}
