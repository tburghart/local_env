diff --git a/lib/wx/c_src/wxe_impl.cpp b/lib/wx/c_src/wxe_impl.cpp
index f81d0bbbd9..46f18fc2e8 100644
--- a/lib/wx/c_src/wxe_impl.cpp
+++ b/lib/wx/c_src/wxe_impl.cpp
@@ -666,7 +666,7 @@ void * WxeApp::getPtr(char * bp, wxeMemEnv *memenv) {
     throw wxe_badarg(index);
   }
   void * temp = memenv->ref2ptr[index];
-  if((index < memenv->next) && ((index == 0) || (temp > NULL)))
+  if((index < memenv->next) && ((index == 0) || (temp != NULL)))
     return temp;
   else {
     throw wxe_badarg(index);
@@ -678,7 +678,7 @@ void WxeApp::registerPid(char * bp, ErlDrvTermData pid, wxeMemEnv * memenv) {
   if(!memenv)
     throw wxe_badarg(index);
   void * temp = memenv->ref2ptr[index];
-  if((index < memenv->next) && ((index == 0) || (temp > NULL))) {
+  if((index < memenv->next) && ((index == 0) || (temp != NULL))) {
     ptrMap::iterator it;
     it = ptr2ref.find(temp);
     if(it != ptr2ref.end()) {
