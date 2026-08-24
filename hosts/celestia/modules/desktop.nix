{ config, lib, pkgs, inputs, ... }:
{

  home.packages = with pkgs;[
    (brave.override {
      commandLineArgs = [
        "--enable-cmd-decoder=passthrough"
        "--enable-features=WaylandLinuxDrmSyncobj,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,CanvasOopRasterization,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
        "--enable-features=UseMultiPlaneFormatForHardwareVideo"
        "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })
    (google-chrome.override {
      commandLineArgs = [
        "--enable-cmd-decoder=passthrough"
        "--enable-features=WaylandLinuxDrmSyncobj,AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoDecodeLinuxGL,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,CanvasOopRasterization,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
        "--enable-features=UseMultiPlaneFormatForHardwareVideo"
        "--enable-features=AcceleratedVideoEncoder"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })

    # zen twilight only — stable removed (twilight supersedes it)
    inputs.zen-browser.packages."${pkgs.system}".twilight
    zathura
    localsend
    seahorse
    libsecret
    nautilus
    helvum




    gtk3
    gtk4
    glib

    vulkan-tools

    xwayland-satellite

    zip
    xz
    unzip
    p7zip

    jq

    bluez
    bluetui
    powertop
    yazi
    xdg-desktop-portal-termfilechooser
    qview
    # inkscape
    mpv
    ffmpeg
    v4l-utils
  ];
}
