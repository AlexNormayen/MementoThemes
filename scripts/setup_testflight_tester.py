"""Automatically create Internal & External TestFlight groups for MementoThemes, add fowl_348@mail.ru, and attach the latest uploaded build."""

import json
import pathlib
import time
import urllib.error
import urllib.request
import jwt

ISSUER = "4178b5af-2d2d-414f-ba80-ce236a4bb048"
KEY_ID = "7MA636HK4K"
P8 = pathlib.Path(r"c:\Users\fowl_\Downloads\AuthKey_7MA636HK4K.p8").read_text(encoding="utf-8")
BASE = "https://api.appstoreconnect.apple.com"
BUNDLE_ID = "ru.theinquisitor.mementothemes"
USER_EMAIL = "fowl_348@mail.ru"


def tok() -> str:
    n = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": n, "exp": n + 1199, "aud": "appstoreconnect-v1"},
        P8,
        algorithm="ES256",
        headers={"alg": "ES256", "kid": KEY_ID, "typ": "JWT"},
    )


def api(method: str, path: str, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        BASE + path,
        data=data,
        method=method,
        headers={
            "Authorization": "Bearer " + tok(),
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode(errors="replace")
        return e.code, json.loads(raw) if raw.startswith("{") else {"raw": raw}


def main():
    c, apps = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    items = apps.get("data", [])
    if not items:
        print(f"[!] Карточка приложения {BUNDLE_ID} ещё не создана в App Store Connect (My Apps -> + -> New App).")
        return
    app_id = items[0]["id"]
    print(f"[+] Найдено приложение в App Store Connect: id={app_id} ({items[0]['attributes']['name']})")

    # 1. Check or create Internal Beta Group "Internal"
    c, groups = api("GET", f"/v1/apps/{app_id}/betaGroups")
    internal_group_id = None
    for g in groups.get("data", []):
        if g["attributes"].get("isInternalGroup"):
            internal_group_id = g["id"]
            print(f"[+] Внутренняя группа уже существует: {g['attributes']['name']} ({internal_group_id})")
            break

    if not internal_group_id:
        c, created = api("POST", "/v1/betaGroups", {
            "data": {
                "type": "betaGroups",
                "attributes": {
                    "name": "Internal",
                    "isInternalGroup": True,
                    "hasAccessToAllBuilds": True,
                },
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}}
                },
            }
        })
        print(f"[+] Создана внутренняя группа Internal: HTTP {c}")
        if "data" in created:
            internal_group_id = created["data"]["id"]

    # 2. Ensure betaTester for fowl_348@mail.ru exists and is attached to internal_group_id
    c, testers = api("GET", f"/v1/betaTesters?filter[email]={USER_EMAIL}")
    tester_ids = [t["id"] for t in testers.get("data", [])]
    if not tester_ids and internal_group_id:
        c, new_t = api("POST", "/v1/betaTesters", {
            "data": {
                "type": "betaTesters",
                "attributes": {
                    "email": USER_EMAIL,
                    "firstName": "Alexandr",
                    "lastName": "Kaveshnikov",
                },
                "relationships": {
                    "betaGroups": {"data": [{"type": "betaGroups", "id": internal_group_id}]}
                },
            }
        })
        print(f"[+] Создан и добавлен тестер {USER_EMAIL}: HTTP {c}")
    elif internal_group_id:
        for tid in tester_ids:
            c, _ = api("POST", f"/v1/betaGroups/{internal_group_id}/relationships/betaTesters", {
                "data": [{"type": "betaTesters", "id": tid}]
            })
            print(f"[+] Привязан тестер {USER_EMAIL} ({tid}) к группе {internal_group_id}: HTTP {c}")

    # 3. Also attach latest build if already uploaded
    c, builds = api("GET", f"/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=5")
    b_list = builds.get("data", [])
    if b_list and internal_group_id:
        latest_build_id = b_list[0]["id"]
        c, _ = api("POST", f"/v1/betaGroups/{internal_group_id}/relationships/builds", {
            "data": [{"type": "builds", "id": latest_build_id}]
        })
        print(f"[+] Билд {latest_build_id} привязан к тестовой группе {internal_group_id}: HTTP {c}")


if __name__ == "__main__":
    main()
