$1 == "<key>CFBundleShortVersionString</key>" {
  version = 1
  short = 1
  print $0
  next
}

$1 == "<key>CFBundleVersion</key>" {
  version = 1
  short = 0
  print $0
  next
}

{
  if (version) {
    if (short) {
      print "	<string>" VERSION "</string>";
    }
    else {
      print "	<string>" VERSION ".0</string>";
    }
  }
  else {
    print $0
  }

  version = 0
  short = 0
}
