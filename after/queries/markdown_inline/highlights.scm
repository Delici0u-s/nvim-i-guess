;; extends

; Hide the `"title"` part of [text](url "title") and ![alt](url "title");
; the stock query only conceals the destination.
(inline_link
  (link_title) @conceal
  (#set! conceal ""))

(image
  (link_title) @conceal
  (#set! conceal ""))

; Hide the backslash of escapes like \* \` \# (keep the escaped char).
((backslash_escape) @conceal
  (#offset! @conceal 0 0 0 -1)
  (#set! conceal ""))

; Hide the trailing `\` of a backslash hard line break.
((hard_line_break) @conceal
  (#lua-match? @conceal "^\\")
  (#set! conceal ""))
