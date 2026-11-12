# TODO

## Immurok login and GNOME Keyring integration

Goal: use Immurok for SDDM login and unlock GNOME Keyring without storing the Linux account password in Immurok.

### Current findings

- The graphical login manager is SDDM, using `/etc/pam.d/sddm`.
- SDDM authentication runs as root, so a manual `pam_immurok.so` hook should be accepted by the Immurok daemon.
- Immurok does not officially manage SDDM; this must be treated as an experimental, reversible PAM change.
- The active secrets service is GNOME Keyring, not KWallet.
- Fingerprint authentication does not provide the password GNOME Keyring normally receives from PAM.
- The root filesystem is not LUKS-encrypted, so `pam_systemd_loadkey` cannot reuse a disk-unlock passphrase.
- Hyprlock is a separate problem: its PAM authentication runs as the user and is rejected by Immurok's root/polkit-only authorization policy.

### Plan

- [ ] Keep a logged-in TTY available for recovery before modifying SDDM PAM.
- [ ] Back up `/etc/pam.d/sddm`.
- [ ] Add `pam_immurok.so` to the SDDM authentication stack with a short timeout.
- [ ] Test both Immurok login and password fallback before managing the PAM file through mise.
- [ ] Open Seahorse and assign the GNOME `Login` keyring a unique password that is different from the Linux account password.
- [ ] Store that dedicated keyring password in the Immurok API vault under the name `gnome-keyring`.
- [ ] Keep a separate secure backup of the keyring password for recovery.
- [ ] After a fresh fingerprint login, test unlocking the keyring manually:

  ```bash
  imk get imk://api/gnome-keyring |
    gnome-keyring-daemon --unlock
  ```

- [ ] Confirm applications using `org.freedesktop.secrets` can access their credentials afterward.
- [ ] Determine whether Immurok's authentication cooldown lets the SDDM fingerprint touch also authorize the API-secret read; otherwise expect a second touch.
- [ ] If the manual test works, add a systemd user service that runs the unlock pipeline after the graphical session starts.
- [ ] Ensure the service never places the keyring password in command-line arguments, environment variables, logs, or files.
- [ ] Document removal and recovery steps before making the setup part of normal bootstrap.

### Avoid

- Do not store the Linux account password in Immurok.
- Do not set an empty GNOME Keyring password; that weakens encryption at rest.
- Do not enable SDDM autologin as a substitute for keyring unlocking—it also provides no password to the keyring.
- Do not automate the SDDM PAM change until both fingerprint login and password fallback have been tested successfully.
