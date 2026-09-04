# Machine-local system config — imported by configuration.nix.
#
# Committed with PLACEHOLDER values for the public repo. Keep your real values
# here locally and hide the edits from git:
#   git -C ~/nix-dotfiles update-index --skip-worktree local.nix
# (undo with --no-skip-worktree). On a fresh machine, edit this for that box's
# internal hosts / tweaks, or blank the attrs out.

{ ... }:

{
  # Static /etc/hosts entries for internal services with no public DNS.
  networking.hosts = {
    "10.0.0.1" = [ "git.internal.example" ];
  };
}
