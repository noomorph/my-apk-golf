#include <jni.h>

JNIEXPORT jstring
Java_b_c_MainActivity_getSomeString(JNIEnv* env, jobject mainActivity) {
    return (*env)->NewStringUTF(env, "Hello from JNI 111111 :)");
}