### 0.2.0 / 2024-XX-XX

* Added {Ronin::Web::Spider::Agent#every_javascript_url_string}.
* Added {Ronin::Web::Spider::Agent#every_javascript_relative_path_string}.
* Added {Ronin::Web::Spider::Agent#every_javascript_absolute_path_string}.
* Added {Ronin::Web::Spider::Agent#every_javascript_path_string}.
* Allow {Ronin::Web::Spider::Agent#every_html_comment},
  {Ronin::Web::Spider::Agent#every_javascript every_javascript},
  {Ronin::Web::Spider::Agent#every_javascript_string every_javascript_string},
  {Ronin::Web::Spider::Agent#every_javascript_relative_path_string every_javascript_relative_path_string},
  {Ronin::Web::Spider::Agent#every_javascript_absolute_path_string every_javascript_absolute_path_string},
  {Ronin::Web::Spider::Agent#every_javascript_url_string every_javascript_url_string}, and
  {Ronin::Web::Spider::Agent#every_javascript_comment every_javascript_comment}
  to also yield a `Spidr::Page` block argument for additional context.

### 0.1.1 / 2024-06-19

* Fixed {Ronin::Web::Spider::Agent#every_html_comment} and
  {Ronin::Web::Spider::Agent#every_javascript} when the page's `Content-Type`
  header included `text/html` but lacked a response body, causing `page.doc` to
  be `nil`.
* Fixed a bug in {Ronin::Web::Spider::Agent#every_javascript} where parsed
  JavaScript source code strings containing UTF-8 characters where being
  incorrectly encoded as ASCII-8bit strings, if the page's `Content-Type` header
  did not include a `charset=` attribute.
* Fixed a bug in {Ronin::Web::Spider::Agent#every_javascript_string} where
  inline JavaScript regexes containing the `"` or `'` characters (ex: `/["'=]/`)
  would incorrectly be treated as the beginning or ends of JavaScript string
  literals. Note that while this greatly improves the accuracy of
  {Ronin::Web::Spider::Agent#every_javascript_string}, it still does not
  support parsing JavaScript template literals that may also contain string
  literals (ex: ````Hello \"World\"```` or ````Hello ${myFunc("string literal")}````).

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

[spidr]: https://github.com/postmodern/spidr#readme
