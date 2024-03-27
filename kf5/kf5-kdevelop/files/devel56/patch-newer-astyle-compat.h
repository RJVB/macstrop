diff --git plugins/astyle/astyle_stringiterator.cpp plugins/astyle/astyle_stringiterator.cpp
index 32a97e0ec6..5354bfe90f 100644
--- plugins/astyle/astyle_stringiterator.cpp
+++ plugins/astyle/astyle_stringiterator.cpp
@@ -35,7 +35,7 @@ AStyleStringIterator::~AStyleStringIterator()
 {
 }
 
-astyle::streamoff AStyleStringIterator::tellg()
+std::streamoff AStyleStringIterator::tellg()
 {
   return m_is.pos();
 }
@@ -72,7 +72,7 @@ void AStyleStringIterator::peekReset()
     m_peekStart = -1; // invalid
 }
 
-astyle::streamoff AStyleStringIterator::getPeekStart() const
+std::streamoff AStyleStringIterator::getPeekStart() const
 {
     // NOTE: we're not entirely sure if this is the correct implementation.
     // we're trying to work-around https://bugs.kde.org/show_bug.cgi?id=399048
diff --git plugins/astyle/astyle_stringiterator.h plugins/astyle/astyle_stringiterator.h
index 4424c0766e..d1ebec6fe6 100644
--- plugins/astyle/astyle_stringiterator.h
+++ plugins/astyle/astyle_stringiterator.h
@@ -35,13 +35,13 @@ public:
     explicit AStyleStringIterator(const QString &string);
     ~AStyleStringIterator() override;
 
-    astyle::streamoff tellg() override;
+    std::streamoff tellg() override;
     int getStreamLength() const override;
     bool hasMoreLines() const override;
     std::string nextLine(bool emptyLineWasDeleted = false) override;
     std::string peekNextLine() override;
     void peekReset() override;
-    astyle::streamoff getPeekStart() const override;
+    std::streamoff getPeekStart() const override;
 private:
     QString m_content;
     QTextStream m_is;
