#!/usr/bin/env python3

# targets
targets = [ "otapackage", "recoveryimage", "bootimage" ]

envvars = {
    "LINEAGE_BUILDTYPE": "NIGHTLY",
    "CCACHE_MAXSIZE" : "50G",
    "CCACHE_COMPRESS", "1",
    }

# name: Distro name
# versions: for use with repo init
# prefix: Jenkins job prefix
# url: repo init url
# init_prefix: branch prefixes for repo init, e.g "lineage-" for lineage (e.g "lineage-" + "15.1")
distros = {
    "lineage" : {
        "name": "LineageOS",
        "versions": ["16.0", "17.1"],
        "prefix": "los",
        "url": "git://github.com/LineageOS/android.git",
        "init_prefix": ["lineage-", "cm-"],
        "variants": {
            "lineage-go" : {
                "name": "LineageOS Go",
                "versions": ["16.0", "17.1"],
                "prefix": "los-go",
                },
            },
        "types": ["userdebug", "eng"],
        },

    "rr" : {
        "name": "RessurectionRemix",
        "versions": ["pie", "ten"],
        "prefix": "rr",
        "url" : "https://github.com/ResurrectionRemix/platform_manifest.git",
        "init_prefix": [],
        "types": ["userdebug", "eng"],
        },
}
