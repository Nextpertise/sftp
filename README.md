# Securely share your files

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH) and [MySecureShell](https://mysecureshell.readthedocs.io/en/latest/).

This image is based on the `atmoz/sftp` image, extended to use MySecureShell instead of OpenSSH's internal sftp-server. This allows for bandwidth and connection limits, as well as enhanced ACLs. Then extended again to use s3 storage as possible backend.

# Usage

- Required: define users in command arguments or in file mounted as `/etc/sftp/users.conf`
  (syntax: `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]]...`).
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Add directory names at the end, if you want to create them under the user's
    home directory. Perfect when you just want a fast way to upload something.
- Optional (but recommended): mount volumes.
  - Create a custom `sftp_config` and mount it to `/etc/ssh/sftp_config` to override MySecureShell defaults. See [MySecureShell documentation](https://mysecureshell.readthedocs.io/en/latest/configuration_overview.html) for available options. (**highly recommended**)

# Examples

## Simplest docker run example

```
docker run -p 22:22 -d nextpertise/s3sftp foo:pass:::upload
```

User "foo" with password "pass" can login with sftp and upload files to a folder called "upload". No mounted directories or custom UID/GID. Later you can inspect the files and use `--volumes-from` to mount them somewhere else (or see next example).

## Sharing a directory from your computer

Let's mount a directory and set UID:

```
docker run \
    -v /host/upload:/home/foo/upload \
    -p 2222:22 -d nextpertise/s3sftp \
    foo:pass:1001
```

### S3 example using docker-compose:

```
sftp:
    image: nextpertise/s3sftp
    environment:
      - TZ=Europe/Amsterdam
      - MOUNT_S3=true
      - S3_URL=http://s3host.com/
      - S3_BUCKET=bucketname
      - ACCESS_KEY_ID=key_id
      - SECRET_ACCESS_KEY=access_key
    volumes:
      - ./sftp_users.conf:/etc/sftp/users.conf # < Optional if `command: user:pass:1000:100` is passed
      - ./my_sftp_config_file:/etc/my_sftp_config_file # < Optional
    ports:
        - "2222:22"
    devices:
      - /dev/fuse:/dev/fuse
    security_opt:
      - "apparmor:unconfined"
    cap_add:
      - SYS_ADMIN
```

### Logging in

The OpenSSH server runs by default on port 22, and in this example, we are forwarding the container's port 22 to the host's port 2222. To log in with the OpenSSH client, run: `sftp -P 2222 foo@<host-ip>`

## Store users in config

```
docker run \
    -v /host/users.conf:/etc/sftp/users.conf:ro \
    -v mySftpVolume:/home \
    -p 2222:22 -d nextpertise/s3sftp
```

/host/users.conf:

```
foo:123:1000:100::http://callback.com/trigger/dest?f={filename}&u={user}
bar:abc:1001:100
baz:xyz:1002:100
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d nextpertise/s3sftp \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e:1001'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Logging in with SSH keys

Mount public keys in the user's `.ssh/keys/` directory. All keys are automatically appended to `.ssh/authorized_keys`. User can also directly edit `.ssh/authorized_keys`. In this example, we do not provide any password, so the user `foo` can only login with his SSH key.

```
docker run \
    -v /host/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v /host/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d nextpertise/s3sftp \
    foo::1001
```

