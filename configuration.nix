# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


  boot = {
    # Use the GRUB 2 boot loader.
    loader = {
      grub.enable = true;
      grub.version = 2;
      # Define on which hard drive you want to install Grub.
      grub.device = "/dev/sda";
    };

    kernelModules = [ "tp_smapi" ];
    extraModulePackages = [ config.boot.kernelPackages.tp_smapi ];
  };


  networking = {
    hostName = "T420";
    hostId = "49a4a0e6";
    useDHCP = true;
    interfaceMonitor = {
      enable = true;
  #   beep = true;
    };
    nameservers = [
      "8.8.8.8"
    ];

  #   enableIPv6 = false; # To make wifi work
  #   wireless.enable = true;
    networkmanager.enable = true;
  };

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  # Select internationalisation properties.
  i18n = {
     consoleFont = "lat9w-16";
     consoleKeyMap = "us";
     defaultLocale = "en_US.UTF-8";
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # basic
    zip
    unzip
    fish
    which
    file

    # system
    acpi
    hdparm
    # pmutils

    # x11
    autorandr

      # windowmanager
      bspwm
      sxhkd
      dmenu

    # web
    chromium
    firefox
    wget

    # monitoring
    # conky
    htop
    powertop
    # pstree

    # dev, user env
    git
    meld
    python
    # from https://github.com/magnetophon/nixosConfig
    ranger
      atool
      highlight
      libcaca
      # mediainfo
      perlPackages.ImageExifTool
      poppler

    sublime
  ];


  nixpkgs.config = {
    allowUnfree = true;

    firefox = {
     # enableGoogleTalkPlugin = true;
     enableAdobeFlash = true;
    };

    chromium = {
     enablePepperFlash = true; # Chromium removed support for Mozilla (NPAPI) plugins so Adobe Flash no longer works 
     enablePepperPDF = true;
    };
  };


  programs.bash = {
    enableCompletion = true;

  #  shellAliases = { };

    interactiveShellInit = ''
      function ranger-cd {
        tempfile='/tmp/chosendir'
        ranger --choosedir="$tempfile" "''${@:-$(pwd)}"
        test -f "$tempfile" &&
        if [ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]; then
          cd -- "$(cat "$tempfile")"
        fi
        rm -f -- "$tempfile"
      }

      # This binds Ctrl-O to ranger-cd:
      bind '"\C-o":"ranger-cd\C-m"'
    '';
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # ThinkPad ACPI
  services.acpid = {
    enable = true;
    powerEventCommands = ''
      echo 2 > /proc/acpi/ibm/beep
    '';
    lidEventCommands = ''
      echo 3 > /proc/acpi/ibm/beep
    '';
    acEventCommands = ''
      echo 4 > /proc/acpi/ibm/beep
    '';
  };

  # Avahi - local network discovery
  services.avahi = {
    enable = true;

    hostName = config.networking.hostName;
    publishing = true;

    # browseDomains = [];
    # wideArea = false;
    ipv4 = true;
    ipv6 = false;

    # resolve .local names
    nssmdns = true;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    # autoStart = true;
    enable = true;
    exportConfiguration = true;  # needed?

    vaapiDrivers = [ pkgs.vaapiIntel pkgs.vaapiVdpau ];
    videoDrivers = ["intel"];

    layout = "us,hu";
    # services.xserver.xkbOptions = "eurosign:e";
    xkbOptions = "grp:caps_toggle, grp_led:caps, terminate:ctrl_alt_bksp";

    # use trackpoint exclusively
    synaptics.enable = false;
    displayManager.slim.defaultUser = "kr";
    displayManager.session =  [ {
      name = "bspwm";
      manage = "window";
      start = "
        ${pkgs.sxhkd}/bin/sxhkd -c /etc/nixos/sxhkdrc &
        ${pkgs.bspwm}/bin/bspwm -c /etc/nixos/bspwmrc
      ";
    } ];
    desktopManager = {
       default = "none";
       xterm.enable = false;
    };
    # do not have a desktop manager - nor powermanager, lid will be managed by ACPI/systemd
    displayManager.desktopManagerHandlesLidAndPower = false;

    # configure laptop display & display on dock
    config = ''
      Section "Monitor"
        Identifier      "laptop panel"
      EndSection
      Section "Monitor"
        Identifier      "big display"
        Option  "Primary" "true"
      EndSection    
    '';

    deviceSection = ''
        Option  "Monitor-LVDS1" "laptop panel"
        Option  "Monitor-HDMI3" "big display"
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.kr = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ 
      "wheel"
      "networkmanager"
   ];
  };

}
