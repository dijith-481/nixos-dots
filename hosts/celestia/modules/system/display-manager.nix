{ pkgs, ... }:
{
  services.displayManager.ly.enable = false;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # The command to run tuigreet
        # --time: shows clock
        # --asterisks: hides password characters
        # --remember: remembers last username
        # --cmd niri-session: The command to start your window manager
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = [ pkgs.tuigreet ];
}
