### 0.1.0 / 2023-02-01

* Extracted and refactored from [ronin-web](https://github.com/ronin-rb/ronin-web/tree/v0.3.0.rc1).
* Relicensed as LGPL-3.0.
* Initial release:
  * Requires `ruby` >= 3.0.0.
  * Built on top of the battle tested and versatile [spidr] gem.
  * Provides additional callback methods:
    * `every_host` - yields every unique host name that's spidered.
    * `every_cert` - yields every unique SSL/TLS certificate encountered while
      spidering.
    * `every_favicon` - yields every favicon file that's encountered while
      spidering.
    * `every_html_comment` - yields every HTML comment.
    * `every_javascript` - yields all JavaScript source code from either inline
      `<script>` or `.js` files.
    * `every_javascript_string` - yields every single-quoted or double-quoted
      String literal from all JavaScript source code.
    * `every_javascript_comment` - yields every JavaScript comment.
    * `every_comment` - yields every HTML or JavaScript comment.
  * Supports archiving spidered pages to a directory or git repository.

