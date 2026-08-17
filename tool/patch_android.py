#!/usr/bin/env python3
"""
يُشغَّل بعد `flutter create .` لضبط إعدادات أندرويد:
  - اسم التطبيق بالعربية
  - أذونات الإشعارات والتخزين
  - تفعيل core library desugaring (يتطلبه flutter_local_notifications)
"""
import re
import sys
from pathlib import Path

APP_LABEL = "إدارة محل الخياطة"
DESUGAR = "com.android.tools.desugar_jdk_libs:desugar_jdk_libs:2.1.4"

PERMISSIONS = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.VIBRATE",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.CAMERA",
]

root = Path("android")
failures = []


def patch_manifest() -> None:
    p = root / "app/src/main/AndroidManifest.xml"
    if not p.exists():
        failures.append(f"missing {p}")
        return
    s = p.read_text(encoding="utf-8")

    s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', s, count=1)

    perms = "\n".join(
        f'    <uses-permission android:name="{x}"/>'
        for x in PERMISSIONS
        if x not in s
    )
    legacy = (
        '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"\n'
        '        android:maxSdkVersion="32"/>'
    )
    if "READ_EXTERNAL_STORAGE" not in s:
        perms = perms + "\n" + legacy if perms else legacy

    if perms:
        s = s.replace("<application", perms + "\n\n    <application", 1)

    p.write_text(s, encoding="utf-8")
    print(f"patched {p}")


def patch_gradle() -> None:
    kts = root / "app/build.gradle.kts"
    groovy = root / "app/build.gradle"

    if kts.exists():
        s = kts.read_text(encoding="utf-8")
        if "isCoreLibraryDesugaringEnabled" not in s:
            block = (
                "\n    compileOptions {\n"
                "        isCoreLibraryDesugaringEnabled = true\n"
                "        sourceCompatibility = JavaVersion.VERSION_11\n"
                "        targetCompatibility = JavaVersion.VERSION_11\n"
                "    }\n"
            )
            # أزل compileOptions القديمة إن وُجدت ثم أضف الجديدة
            s = re.sub(
                r"\n\s*compileOptions\s*\{[^}]*\}\n", "\n", s, count=1
            )
            new, n = re.subn(r"(?m)^android\s*\{", "android {" + block, s, count=1)
            if n == 0:
                failures.append("could not locate `android {` in build.gradle.kts")
            else:
                s = new
        if "coreLibraryDesugaring(" not in s:
            s += f'\n\ndependencies {{\n    coreLibraryDesugaring("{DESUGAR}")\n}}\n'
        kts.write_text(s, encoding="utf-8")
        print(f"patched {kts}")

    elif groovy.exists():
        s = groovy.read_text(encoding="utf-8")
        if "coreLibraryDesugaringEnabled" not in s:
            block = (
                "\n    compileOptions {\n"
                "        coreLibraryDesugaringEnabled true\n"
                "        sourceCompatibility JavaVersion.VERSION_11\n"
                "        targetCompatibility JavaVersion.VERSION_11\n"
                "    }\n"
            )
            s = re.sub(r"\n\s*compileOptions\s*\{[^}]*\}\n", "\n", s, count=1)
            new, n = re.subn(r"(?m)^android\s*\{", "android {" + block, s, count=1)
            if n == 0:
                failures.append("could not locate `android {` in build.gradle")
            else:
                s = new
        if "coreLibraryDesugaring " not in s:
            s += f"\n\ndependencies {{\n    coreLibraryDesugaring '{DESUGAR}'\n}}\n"
        groovy.write_text(s, encoding="utf-8")
        print(f"patched {groovy}")

    else:
        failures.append("no app/build.gradle(.kts) found")


def patch_gradle_properties() -> None:
    p = root / "gradle.properties"
    if not p.exists():
        return
    s = p.read_text(encoding="utf-8")
    additions = [
        "org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G",
        "android.useAndroidX=true",
        "android.enableJetifier=true",
    ]
    lines = s.splitlines()
    keys = {ln.split("=")[0].strip() for ln in lines if "=" in ln}
    for a in additions:
        if a.split("=")[0] not in keys:
            lines.append(a)
        else:
            lines = [a if ln.split("=")[0].strip() == a.split("=")[0] else ln
                     for ln in lines]
    p.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"patched {p}")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle()
    patch_gradle_properties()
    if failures:
        print("\n".join(f"ERROR: {f}" for f in failures), file=sys.stderr)
        sys.exit(1)
    print("android patch completed")
