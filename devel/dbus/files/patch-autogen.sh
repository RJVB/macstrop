--- orig.autogen.sh	2015-09-30 16:48:40.000000000 +0200
+++ autogen.sh	2016-09-20 20:33:50.000000000 +0200
@@ -101,5 +104,5 @@
 fi
 
 if $run_configure; then
-    $srcdir/configure --enable-developer --config-cache "$@"
+    $srcdir/configure "$@"
 fi
