#!/usr/bin/env python3
"""
يُشغَّل بعد `flutter create .` لضبط إعدادات أندرويد:
  - اسم التطبيق بالعربية
  - أذونات الكاميرا والصور (لرفع شعار المحل والختم)
لا يحتاج المشروع إلى أي إعدادات Gradle خاصة.
"""
import re
import sys
from pathlib import Path

APP_LABEL = "إدارة محل الخياطة"

PERMISSIONS = [
    "android.permission.CAMERA",
    "android.permission.READ_MEDIA_IMAGES",
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

    lines = [
        f'    <uses-permission android:name="{x}"/>'
        for x in PERMISSIONS
        if x not in s
    ]
    if "READ_EXTERNAL_STORAGE" not in s:
        lines.append(
            '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"\n'
            '        android:maxSdkVersion="32"/>'
        )

    if lines:
        s = s.replace("<application", "\n".join(lines) + "\n\n    <application", 1)

    p.write_text(s, encoding="utf-8")
    print(f"patched {p}")


def patch_gradle_properties() -> None:
    p = root / "gradle.properties"
    if not p.exists():
        return

    lines = p.read_text(encoding="utf-8").splitlines()
    wanted = {
        "org.gradle.jvmargs": "-Xmx4G -XX:MaxMetaspaceSize=2G",
        "android.useAndroidX": "true",
    }
    keys = {ln.split("=")[0].strip() for ln in lines if "=" in ln}
    out = []
    for ln in lines:
        k = ln.split("=")[0].strip() if "=" in ln else None
        out.append(f"{k}={wanted[k]}" if k in wanted else ln)
    for k, v in wanted.items():
        if k not in keys:
            out.append(f"{k}={v}")

    p.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"patched {p}")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle_properties()
    if failures:
        print("\n".join(f"ERROR: {f}" for f in failures), file=sys.stderr)
        sys.exit(1)
    print("android patch completed")
