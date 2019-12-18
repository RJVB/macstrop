diff --git a/vnc/vncsshtunnelthread.cpp b/vnc/vncsshtunnelthread.cpp
index 77f229cb05b8dcffcb094c6b27dd183889b59478..b1a2b90f43aa898002002179963ac340f9587f58 100644
--- a/vnc/vncsshtunnelthread.cpp
+++ b/vnc/vncsshtunnelthread.cpp
@@ -32,6 +32,7 @@
 #include <arpa/inet.h>
 #include <netinet/in.h>
 #include <sys/socket.h>
+#include <errno.h>
 
 #include <QDebug>
 
