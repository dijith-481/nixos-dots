# Celestia thermal and responsiveness investigation

Initial measurements: 2026-09-05 around 21:34–21:45 IST under the existing desktop
workload, initially read-only. The subsequent privileged investigation used run0,
briefly enabled thermald information logging, and tested supported profile/fan
settings with automatic restoration. No kernel or persistent NixOS settings changed.

## Privileged follow-up: stronger evidence

The user reports that fans were louder under Fedora too, and that the Performance
test here caused only a slight increase in fan sound. The Fedora kernel, BIOS at
that time, workload and placement have not yet been established.

### Firmware fan interfaces

The firmware tables were copied and decompiled locally, without executing their
methods through an ACPI debugging tool. In the inspected DSDT and SSDT tables,
the generic ACPI fans call `LPCB.UPFS`, which only operates when `LPCB.H_EC`
exists. The actual EC device defined is `LPCB.Q_EC`. The temperature helper
`MXTP` similarly returns the constant `0x0BC2` (27.8°C) when `H_EC` is absent.
Consequently the five generic ACPI Fan controls and their low reported thermal
zone are not usable evidence of actual physical fan speed on this firmware.
Adding CPU-to-Fan bindings to these interfaces is not a justified repair.

The working Lenovo DYTC method uses the Q_EC path and issues EC commands for
Balanced, Performance and Quiet. The loaded `ideapad-laptop` driver exposes this
through platform_profile. This is not evidence of a missing proprietary fan driver.

An initial 15-second test of legacy `fan_mode=4` read back 4 on every sample.
Its prior readback of 1 therefore does not establish that writes are ignored.
The original value 1 was restored. Temperatures during that short trial were
96–103°C; that interval alone is too short to establish its cooling effect.

A subsequent 59.1-second measured interval at fan mode 4, keeping Balanced,
averaged 98.5°C at 18.75 W, with package throttling for 42.5% of the interval.
The preceding 7-second baseline was 98.9°C / 19.45 W / 65.6% throttling;
the following 9-second recovery was 100.6°C / 19.96 W / 58.8% throttling.
Readback remained 4 throughout. This may indicate some benefit, but the varying
workload and short baseline prevent quantifying it. It clearly did not resolve
the sustained heat/throttling during this test. The original fan mode 1 was
restored, with Balanced verified afterwards. Data is in
`/tmp/celestia-fan-cooling-check.jsonl`.

### What thermald actually does

Information logging verified that adaptive mode succeeds and parses Lenovo's
embedded data vault. A missing optional `/lib/firmware/intel/dtt/` file is followed
by successful firmware-table parsing; it is not proof of missing required firmware.
The selected target is `Intelligent default Mode STD 5_AC`. It binds SEN1 to
the MMIO RAPL controller with a 46°C passive trip and selects a 25 W upper /
22 W lower PL1 range, plus 48 W PL2. The measured SEN1 value (~77°C) pushes
that range to 22 W. The logged selected policy contains no active fan binding.

Earlier inspection of only the MSR RAPL interface was incomplete: thermald
explicitly uses the **MMIO** interface. Therefore the earlier 32 W / 100 W
MSR readings should not be presented as the effective thermal policy limits.
Neither a functioning thermald process nor a functioning power cap establishes
adequate heat removal.

The packaged `thermald-features.xml` has `DbusControl=0`, which also rejects
its Get diagnostic calls, even with `--dbus-enable`. This is a diagnostic-access
limitation, not itself a cooling failure. A temporary runtime logging override
was removed, and the original service was verified active afterwards.

### Controlled profile comparison

The same ongoing user workload was observed, with no synthetic load. This is a
short diagnostic comparison, not a repeatable benchmark; workload may vary.

| Stage | Observed interval | Mean CPU temperature | Mean package power | Package throttle time |
|---|---:|---:|---:|---:|
| Balanced before | 7.0 s | 97.5°C | 18.70 W | 43.0% |
| Performance | 29.1 s | 99.8°C | 19.96 W | 72.0% |
| Balanced after | 14.0 s | 97.7°C | 17.74 W | 28.8% |

Performance read back correctly, changed EPP to performance, set firmware OEM8
to 1 and raised the MMIO PL1 to 33 W. Thus the profile command reached firmware
and affected policy. It did not demonstrate improved cooling. Balanced was
restored and MMIO PL1 returned to 22 W. Do not make Performance the default on
the basis of this test.

### Display waits confirmed, causality still limited

Root stacks repeatedly identified `drm_atomic_helper_wait_for_flip_done` inside
`intel_atomic_commit_tail`. Debugfs confirms PSR really is disabled. Waiting for
display completion explains why graphics workers appear in I/O pressure; its
presence alone does not establish an abnormal frame delay or explain overheating.
No claim is made that the same worker was continuously stuck between samples.
Some `rg` disk waits during this capture were caused by this investigation's own
Nix-store filename search, not by the user's original workload.

The simultaneous privileged 30-second capture recorded 96–101°C, package power
around 18.6–21.6 W per interval, and 16.744 seconds of package thermal throttling.
Poor cooling at this workload is confirmed. The remaining distinction is firmware
fan behaviour versus a physical heat-removal problem; neither a replacement
thermal manager nor a speculative kernel patch is established as a fix.

Raw local evidence: `/tmp/celestia-thermal-root.json`,
`/tmp/celestia-thermald-info.log`, `/tmp/celestia-profile-check.jsonl`,
`/tmp/celestia-fan-mode-check.jsonl`, and `/tmp/celestia-acpi-analysis/`.
These temporary files may disappear on reboot.

## Initial read-only findings (retain the follow-up qualifications above)

Hardware: Lenovo Yoga Slim 7 14IMH9, type 83CV, Core Ultra 7 155H,
approximately 32 GB RAM. BIOS NPCN39WW (2025-12-31). Running kernel 7.2.0.
The booted and current NixOS system paths match.

### 1. Sustained thermal throttling is confirmed

In a 30.17-second observation, package temperatures were 101, 102, 98, 100,
100 and 99°C. CPU0's package throttle time increased by 20,535 ms, approximately
68% of the interval; its package event counter increased by 2,590. These are
interval deltas, not just historical counters. Do not sum package counters across
CPUs: package notifications are broadcast to multiple CPUs.

Aggregate CPU busy time was 15.66% across 22 logical CPUs. This does not exclude
individual busy cores, and throttling itself reduces the work the CPU can do.
A subsequent six-sample GPU capture reported package power of 17.2–21.2 W.
That short power sample is not a measurement of earlier peak power or a controlled
cooling-capacity test, but the system is clearly not simply running an all-core
benchmark. The kernel also logged thermal throttling repeatedly earlier this boot.

Cooling policy/firmware behaviour is a leading suspect. The user's observation
that Windows makes the fans noticeably louder strengthens that suspicion;
it does not exclude restricted airflow, heatsink contact, or fan hardware problems.

### 2. The configured fan override is not the observed fan mode

`hosts/celestia/modules/system/power.nix` writes `4` to the legacy Lenovo
`fan_mode` interface after selecting the power profile. The running service
contains that code and last completed successfully at 18:22:55. Current readback
is `1`. Upstream documents 1 as Standard and 4 as Efficient Thermal Dissipation.

This proves a configuration/readback mismatch. It does NOT prove whether the
firmware ignored the write, reset it later (there was a suspend/resume at 21:07),
or treats this legacy interface differently on this model. The service has no
readback verification and no explicit resume hook. Repeatedly forcing the value
without first testing its meaning is not a justified fix.

The active modern platform-profile provider is `ideapad-laptop`, reporting
`balanced`. The `lenovo_wmi_gamezone` probe warning does not mean all platform
profile support is broken: another provider is working.

Five ACPI Fan cooling devices report current state 0 and maximum state 1.
All five are bound to `thermal_zone0` (`acpitz`), which reports 27.8°C and has
active trip temperatures starting at 40°C. The separate TCPU sensor reports
roughly 100°C; its listed active trips start at 103.05°C, and no `cdev` links
were exposed there during inspection. No fan RPM or PWM interface was found.
These ACPI controls therefore do not establish actual fan speed or the EC's
internal policy. They also do not establish that the laptop has five physical fans.

### 3. Graphics waiting remains a credible, separate source of lag

I/O pressure was high: at the end of the 30-second sample, `io.some avg10` was
38.98% and `io.full avg10` was 32.64%. A blocked kernel worker was named
`kworker/u93:2+i915_flip` (PID 399539 at the time).

Meanwhile the NVMe recorded only 542 ms of busy time over 30.17 seconds
(approximately 1.8% utilization), 40 KiB read and 30 MiB written. There was no
swap use or memory pressure. This points toward graphics-related waiting rather
than a saturated SSD. A kernel stack is still required to identify the exact wait;
the worker name alone does not prove which function or driver defect caused it.

`i915.enable_psr=0` is already in the running kernel command line. Existing
configuration comments claim PSR and cursor updates caused flip waits, but the
current evidence shows that workaround has not eliminated the symptom. Do not
claim another PSR toggle or a kernel-family change will fix it without an A/B test.

A boot-time i915 warning references VBT voltage-swing/pre-emphasis tables in
`intel_bios_init`. It is a firmware/display clue, not proof of the ongoing stall.

### 4. Several commonly suggested fixes are unsupported by this capture

- About 18 GiB RAM was available; 12.3 GiB zram swap was entirely unused and
  memory PSI was zero. More swap or different swappiness does not address this sample.
- `thermald --adaptive` and power-profiles-daemon are active. TLP, auto-cpufreq
  and tuned services are absent. There is no evidence of those managers fighting.
- Intel pstate is active, using `powersave` and EPP `balance_performance` on AC,
  with turbo available. This governor name does not mean the CPU is locked slow.
- GPU render and hardware video engines are active; Zen's RDD process appeared
  among GPU clients. Blanket claims that all browser rendering/video uses software
  are unsupported. This does not verify acceleration for every tab or codec.
- Zen's parent and a web-content process were the largest CPU consumers in the
  sample (about 66% and 63% of one CPU respectively). Desktop/ChatGPT activity
  also contributed. These are workload contributors, not evidence of a browser bug.
- Configured package limits read as 32 W long-term and 100 W short-term. Those
  are ceilings, not measured consumption. Arbitrarily lowering them or disabling
  turbo could conceal the cooling problem while worsening responsiveness.
- Battery was not charging and conservation mode was active.

## Initial capture procedure (completed with run0 in the follow-up)

Run the adjacent read-only script while the usual lag/heat is happening:

```sh
sudo /etc/profiles/per-user/dijith/bin/python3 /home/dijith/nixos-dots/docs/capture-thermal.py > /tmp/celestia-thermal-root.json
```

It samples for about 30 seconds, reads kernel stacks of blocked threads and
graphics/thermal state, and writes JSON only to stdout. It does not change
settings, load modules, install packages, or create artificial CPU load.
The redirect creates the output as the invoking user. Root is needed for stacks,
RAPL energy and debugfs; without root the output records access errors.

Use those results to identify the graphics wait and inspect the firmware thermal
state. Then make one controlled comparison of a supported Lenovo profile under
the same workload, observing temperature, package watts, throttling and fan sound.
A performance profile can raise power limits as well as fan speed, so louder fans
alone are not a successful result. Record and restore the prior profile.

If firmware/profile changes cannot produce adequate cooling at modest sustained
power, compare with the manufacturer's diagnostics/cooling behaviour and inspect
the cooling hardware. This investigation has not verified whether a newer BIOS
exists or whether one addresses these symptoms.

## Remaining discriminating check

Compare a fresh boot of a Fedora live environment with a fresh NixOS boot, on
the same hard surface with unobstructed vents, at comparable measured package
power and with the same workload and profile. Capture behaviour before any
suspend/resume. This needs user participation and was not performed here.

If Fedora now cools substantially better at comparable power, compare its
kernel, thermald launch flags/version, platform-profile provider and firmware
state. If it is equally hot, the older Fedora experience does not isolate the
current NixOS configuration; firmware changes, airflow and cooling hardware
need attention. Do not assume that similar CPU percentages imply equal power.

## Upstream references

- [Intel thermal counters and their meaning](https://www.kernel.org/doc/html/latest/admin-guide/thermal/intel_thermal_throttle.html)
- [Lenovo legacy fan-mode ABI](https://raw.githubusercontent.com/torvalds/linux/master/Documentation/ABI/testing/sysfs-platform-ideapad-laptop)
- [ACPI fan state and RPM interfaces](https://docs.kernel.org/admin-guide/acpi/fan_performance_states.html)
- [Intel pstate governor and EPP behaviour](https://cdn.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html)
