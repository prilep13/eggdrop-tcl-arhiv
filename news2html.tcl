# Script: News 2 HTML 
# Author: Wingman <Wingman@WINGDesign.de>
#         http://www.WINGDesign.de/
# BugFix: Kyle Masters <SpEaRmAn@OvertechTechnologies.com
#         http://overtechtechnologies.com
# no < allowed in add... prevents ppl from inputting html code!

# [filename] where is the html file?
set n2h(html) "index.html"

# [string] where should i insert the news?
# You have to put this line into your html file 
set n2h(match) "<!-- insert news here -->"

# [command] what command should be used for adding news?
set n2h(cmd) "addnews"

# [global_flag|/&chan_flag] what flags are authorized for using News 2 HTML?
set n2h(cmd_flags) "o|o"

set n2h(ver) "1.1"

bind msg $n2h(cmd_flags) $n2h(cmd) msg:n2h

proc n2h:addnews { handle news } {
  global n2h
  if {![file exists $n2h(html)]} { return 0 }
  set file [open $n2h(html) r]
  while {![eof $file]} {
    lappend foo [gets $file]
  }
  close $file
  set file [open $n2h(html) w]
  foreach line $foo {
    puts $file $line
    if {[string match "*$n2h(match)*" $line]} {
      set found 1 
      # looks like this:
      # ---
      # Wingman (Mon 01 99 at 01:01): this script roxx :)
      # ---
      # [strftime "%d %b %Y"] -> Mon 01 99
      # [strftime "%H:%M"]    -> 01:01
      # $news                 -> news
      # $handle               -> nickname
      # ---
      # EDIT HERE
      puts $file "$handle ([strftime "%d %b %Y"] at [strftime "%H:%M"]): $news"
    }
  }
  close $file
  if {![info exists found]} { return 2 }
  return 1
}
      
proc msg:n2h { nick uhost handle arg } {
 if {![lsearch $arg *<*]} {
  putserv "NOTICE $nick :No using html code in your posts!"
 } else {
  global n2h
  if {[llength $arg] < 1} {
    putserv "PRIVMSG $nick :Usage: $n2h(cmd) <news>"
    return 0
  }
  putserv "PRIVMSG $nick :Updated news: \"$arg\"."
  set code [n2h:addnews $handle "$arg"]
  switch -exact $code {
    "0" { putlog "News2Html $n2h(ver) ERROR: Can't find $n2h(html)." ; return 0 }
    "1" { return 1 }
    "2" { putlog "News2Html $n2h(ver) ERROR: Can't find \"$n2h(match)\" in $n2h(html)." ; return 0 }
  }
 }
}

putlog "News2Html $n2h(ver) by Wingman [Bugfix SpEaRmAn] loaded."
