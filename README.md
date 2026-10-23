# YARP recovery build for Xiaomi SM8850

Builds the upstream TWRP-Test recovery with its default LVGL GUI2 / YARP
interface and the upstream unified Xiaomi SM8850 device tree. The device tree
includes Xiaomi 17 Pro (`pandora`). No device or decryption patches are added.

Run **Actions > Build YARP SM8850 > Run workflow**. The workflow produces a
recovery image, SHA256 checksum, static verification report, resolved source
manifest and build logs. Artifacts are retained for 14 days.

The manifest, recovery, LVGL, recording libraries and device tree are pinned in
`sources.json`. Other project revisions are recorded in the resolved manifest
after synchronization. The build runs `mka installclean` before
`mka recoveryimage`, as required by the upstream GUI2 build instructions.

The generated image is a ramdisk-only SM8850 recovery image with an Android v4
boot header. It is not a complete kernel boot image. Producing and checking this
artifact does not verify boot, touchscreen behaviour or data decryption on any
particular installed firmware.

## Sources

- [Recovery / YARP](https://github.com/TWRP-Test/android_bootable_recovery/tree/twrp-16.0)
- [SM8850 device tree](https://github.com/TWRP-Test/twrp_device_xiaomi_sm8850/tree/twrp-16.0)
- [Build manifest](https://github.com/TWRP-Test/platform_manifest_twrp_aosp/tree/twrp-16.0)
- [GUI2 build instructions](https://github.com/TWRP-Test/android_bootable_recovery/blob/twrp-16.0/gui2/AGENTS.md)

Upstream code is fetched from its original repositories and retains its original
licenses. Disk preparation runs only on the disposable GitHub-hosted Linux runner.

## Hosted runner resource limits

The first run lost its runner connection during the build; GitHub did not retain
a compiler failure log. Resource exhaustion is a possibility, not a confirmed
diagnosis. The workflow now uses the existing root filesystem instead of LVM
loop images, frees unused preinstalled SDKs, and allocates 16 GiB of swap. It
requires 95 GiB free before source sync and 15 GiB afterwards.

Builds use two jobs, a single Soong bootstrap job, and the upstream
`SOONG_GOMEMLIMIT=8GiB` option. A systemd scope caps build RAM at 13 GiB and swap
at 12 GiB to leave resources for the Actions agent. Resource reports are written
every minute by the runner; no external polling is required. A disk guard stops
the build below 3 GiB free so diagnostic logs can still upload.
