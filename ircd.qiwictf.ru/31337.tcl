# some shit for 1337 :)
package require http 2.0
http::config

namespace eval leet {

  variable channel "#31337"

  bind pub - !help leet::help
  bind pub - !wget leet::wget_pub
  bind msg - !wget leet::wget_priv
}

proc sendmulti { chan messages } {
  foreach msg $messages {
    putserv "PRIVMSG $chan :$msg"
  }
}

proc start_download { nick url } {
  set file "/tmp/${nick}_wget"
  set out [open $file w]
  fconfigure $out -translation binary

  if {[catch {http::geturl $url -channel $out} f]} {
    putserv "PRIVMSG $nick :Download $url failed: $f"
    close $out
  } else {
   close $out
   if { [catch {dccsend $file $nick} f] } {
     putserv "PRIVMSG $nick :DCC file failed: $f"
     return
    }
    if { $f } {
      putserv "PRIVMSG $nick :DCC file returned $f"
    }
  }
}


proc leet::help { nick host hand chan text } {
  if { $chan == $leet::channel } {
    sendmulti $chan [list "Try these commands:" "!ping x.x.x.x - to ping something" "!traceroute x.x.x.x to traceroute" "!wget http://site.com/1337.txt - to get back a file ( via DCC )" ]
  }
}

proc leet::wget_pub { nick host hand chan text } {
  start_download $nick $text
  sendmulti $chan [list "$nick: your download of $text is started. You will get a DCC FILE when it is ready"]
}

proc leet::wget_priv { nick host hand text } {
  if { [onchan $nick $leet::channel] == 1 } {
    puts "Got $text (p)"
    puts "wget $text -O xxx"
  }
}

