--- orig.autogen.sh	2015-09-30 16:48:40.000000000 +0200
+++ autogen.sh	2016-09-20 20:33:50.000000000 +0200
@@ -81,7 +81,10 @@
 (autoheader --version)  < /dev/null > /dev/null 2>&1 && autoheader
 
 $AUTOMAKE -a $am_opt
-autoconf || echo "autoconf failed - version 2.5x is probably required"
+if ! autoconf; then
+  echo "autoconf failed - version 2.5x is probably required" >&2
+  exit 1
+fi
 
 cd $ORIGDIR
 
@@ -101,5 +104,5 @@
 fi
 
 if $run_configure; then
-    $srcdir/configure --enable-developer --config-cache "$@"
+    $srcdir/configure "$@"
 fi
