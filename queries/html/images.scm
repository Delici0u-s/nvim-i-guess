; Override of snacks.nvim's queries/html/images.scm.
; Upstream captures the whole `element` for <img>. In markdown, all HTML
; blocks are parsed as one combined injection, so a void `<img ...>` (no />)
; becomes an element that runs until the next closing tag far below. With
; snacks' conceal enabled that hid/broke everything after the image.
; Capturing only the start tag keeps the image range on its own line.

(start_tag
  (tag_name) @tag (#eq? @tag "img")
  (attribute
    (attribute_name) @attr_name (#eq? @attr_name "src")
    (quoted_attribute_value (attribute_value) @image.src)
  )
) @image

(self_closing_tag
  (tag_name) @tag (#eq? @tag "img")
  (attribute
    (attribute_name) @attr_name (#eq? @attr_name "src")
    (quoted_attribute_value (attribute_value) @image.src)
  )
) @image

(element
  (start_tag (tag_name) @tag (#eq? @tag "svg"))
  (#set! image.ext "svg")
) @image @image.content
