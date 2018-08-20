IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_I => "Bridge >> ",
  :PROMPT_S => "%l>> ",
  :PROMPT_C => ">>",
  :PROMPT_N => ">>",
  :RETURN => "=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM
IRB.conf[:AUTO_INDENT] = true
include Bridge
puts ">> I am Bridge Console".white.bg_black