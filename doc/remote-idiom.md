# Remote-user file encryption

This file is not directly related to the project. It explains a workflow for
remote developers connecting over SSH. If you forward your SSH agent, you can
use your in-memory public SSH key to encrypt files for yourself on remote
systems.

I think this is more interesting than useful.

## Overview

Encrypt a remote file using the public key of the connected SSH user, so only
that user may decrypt it on a system with the corresponding private key.

You must forward your SSH agent to get your public key with `ssh-add -L`.
To do so, edit `$HOME/.ssh/config` to include something like:

```ssh-config
Host *
	ForwardAgent yes
	AddKeysToAgent yes
	UseKeychain yes
	IdentityFile "$HOME/.ssh/id_ed25519"
```

## Dependencies

- [age](https://github.com/FiloSottile/age)

  ```shell
  sudo apt install --yes age
  ```

- [ssh-to-age](https://github.com/Mic92/ssh-to-age)

  ```shell
  go install github.com/Mic92/ssh-to-age/cmd/ssh-to-age@latest

  # (Make sure "$(go env GOPATH)"/bin is in your PATH!)
  # or

  mkdir -p "$HOME"/.local/bin
  wget -O "$HOME"/.local/bin/ssh-to-age \
    "https://github.com/Mic92/ssh-to-age/releases/download/1.2.0/ssh-to-age.linux-amd64"

  # (Make sure $HOME/.local/bin is in your PATH!)
  ```

## Usage

```shell
age --encrypt \
	--recipient "$(ssh-to-age <<<"$(ssh-add -L | head -n1)")" \
	--output secret.txt.age \
	secret.txtm

# (on computer with private key)

# Enter private key passphrase if needed:
# Remember to unset SSH_TO_AGE_PASSPHRASE as soon as possible!
echo 'Keyfile passphrase:'
read -s SSH_TO_AGE_PASSPHRASE; export SSH_TO_AGE_PASSPHRASE

age --decrypt \
  --identity <(ssh-to-age -private-key -i "$HOME"/.ssh/id_ed25519) \
  secret.txt.age && unset SSH_TO_AGE_PASSPHRASE
```
