# Self Host Reference Guide

<!-- markdownlint-disable MD033 -->

Here's a guide I found on Reddit, copied and formatted in Markdown here for
archival.

- > [**Original post** (Aug 9, 2024)](https://www.reddit.com/r/selfhosted/comments/1eo7knj/guide_obsidian_with_free_selfhosted_instant_sync/)  
    Copied Dec 2, 2025<br>
    From `r/selfhosted`<br>
    By `u/Timely_Anteater_9330`

***
***

## Guide: Obsidian with free, self-hosted, instant sync

TLDR: I've been using Obsidian with the
[LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin by
[vrtmrz](https://github.com/vrtmrz) for over a month now and not counting the
Arr stack, this plugin is without a doubt, the single-best self-hosted service
that I run on my server. I use it multiple times a day and at this point I can't
live without it. So I decided to contribute back to the community, which has
taught me so much, by sharing my experience and also writing a detailed guide. I
found that most guides gloss over crucial steps, but then again I rarely know
what I'm doing, so take my guide with a pinch of salt.

### Story time

I recently went on a journey of trying to find a replacement to Apple Notes
which I documented
[here](https://www.reddit.com/r/selfhosted/comments/1dnx38z/apple_notes_replacement/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
and I was looking for something that checked the following boxes:

  1. Able to self-host on my Unraid server.
  2. Must have an iOS app, not something accessed in a browser.
  3. Sync my notes between all my devices instantly and seamlessly.

On this wonderful sub-Reddit, Obsidian was constantly recommended. So I
downloaded both the Windows 11 app on my desktop and the iOS app on my iPhone,
and was extremely pleased how polished it was. It's not open source but I was
willing to overlook that.

Then I ran into the roadblock of syncing my notes between devices, which
Obsidian does offer a service called Obsidian Sync for $4 a month but I wanted
to self-host this aspect, I didn't want to rely on someone else (personal
preference). If you don't want to self-host the syncing I highly recommend you
support the company by using their sync service.

I was recommended a plugin for Obsidian called
[LiveSync](https://github.com/vrtmrz/obsidian-livesync) by
[vrtmrz](https://github.com/vrtmrz) which allows you to self-host the syncing
process. Below is a detailed guide on how to set this up.

### How it works

This "service" has 3 moving parts to it. The Obsidian app, the LiveSync plugin
and the CouchDB database in a docker container. Here is a breakdown of each:

  1. Obsidian app: You install the app on each device. I use it on an iPhone,
     iPad, Windows 10 laptop, Windows 11 desktop and a web client (docker
     container from
     [Linuxserver](https://docs.linuxserver.io/images/docker-obsidian/)). Each
     device has a local copy of your notes so you can still use it offline.

  2. CouchDB: This is where a copy of your notes will be stored (encryption is
     an option and also recommended).

  3. LiveSync plugin: The plugin is what does all the heavy lifting of syncing
     all your devices. It accomplishes this by connecting to your self-hosted
     CouchDB docker container and storing an encrypted copy there. All your
     other devices will connect to the database to grab the updated notes
     allowing for an instant sync.

### Docker Compose on Unraid

Below is the docker compose file just to get CouchDB up and running. I installed
this on an Unraid server so you can edit the labels and environment variables
for your specific OS.

```yaml
couchdb-obsidian-livesync:
  container_name: obsidian-livesync #shortened name
  image: couchdb:3.3.3
  environment:
    - PUID=99
    - PGID=100
    - UMASK=0022
    - TZ=America/New_York
    - COUCHDB_USER=obsidian_user # optionally change me
    - COUCHDB_PASSWORD=password # definitly change me
  volumes:
    - /mnt/user/appdata/couchdb-obsidian-livesync/data:/opt/couchdb/data
    - /mnt/user/appdata/couchdb-obsidian-livesync/etc/local.d:/opt/couchdb/etc/local.d
  ports:
    - "5984:5984"
  restart: unless-stopped
  labels:
    - net.unraid.docker.webui=http://[IP]:[PORT:5984]/_utils # for some reason this does not work properly
    - net.unraid.docker.icon=https://couchdb.apache.org/image/couch@2x.png
    - net.unraid.docker.shell=bash
```

### CouchDB - Initial Configuration

  1. Go to the CouchDB admin page by going here: `http://192.168.1.0:5984/_utils`
     make sure to use your server's IP address.

  2. Login using the credentials you set in the Docker compose file.

  3. Click on the <-> icon on the top left, it will expand the menu from simple
     icons to icons with text which will make following this guide easier.

  4. Click on Setup on the left menu.

  5. Click on Configure as Single Node and enter the same credentials from the
     Docker compose file into the Specify your Admin credentials fields.

  6. Leave everything else the same and click Configure Node.

### CouchDB - Verify Installation

  1. Let's verify the CouchDB installation by clicking Verify on the left menu.

  2. Click Verify Installation and if everything is good, a popup banner should
     popup saying Success! Your CouchDB installation is working. Time to Relax.
     along with 6 check marks next to each item in the table.

### CouchDB - Create Database

  1. Click on the Databases on the left menu.

  2. Click on Create Database on the top right.

  3. Under Database Name enter obsidiandb, or whatever you like. Advice: if you
     intend to use this setup for multiple users, each user will need their own
     database, so I recommend naming the database to include the user's first
     name like: obsidiandb_john or obsidiandb_jane just to make it easier in the
     future.

  4. Under Partitioning select Non-partitioned - recommended for most workloads.
     Once the database is created, you should be redirected to the new
     database's config page. You don't have to do anything here.

### CouchDB - Configuration

  1. Click on Configuration on the left main menu. The following 9 config
     entries are what the script was intended to do automatically but I wanted
     to do it manually. Click on + Add Option on the top right for each entry:

     1. Section: `chttpd`  
        Name: `require_valid_user`  
        Value: `true`

     2. Section: `chttpd_auth`  
        Name: `require_valid_user`  
        Value: `true`

     3. Section: `httpd`  
        Name: `WWW-Authenticate`  
        Value: `Basic realm="couchdb"`

     4. Section: `httpd`  
        Name: `enable_cors`  
        Value: `true`

     5. Section: `chttpd`  
        Name: `enable_cors`  
        Value: `true`

     6. Section: `chttpd`  
        Name: `max_http_request_size`  
        Value: `4294967296`

     7. Section: `couchdb`  
        Name: `max_document_size`  
        Value: `50000000`

     8. Section: `cors`  
        Name: `credentials`  
        Value: `true`

     9. Section: `cors`  
        Name: `origins`  
        Value: `app://obsidian.md,capacitor://localhost,http://localhost`

### Obsidian - Windows 11 Client

  1. Download and install the Windows 11 Obsidian client from
     [here](https://obsidian.md/download).

  2. Once installed, open Obsidian.

  3. Next to Create new vault click the Create button next.

  4. In the Vault name field, name your Vault whatever you like, I simply named
     mine Vault. You can think of a vault as a "master folder" that contains all
     your folders and notes. Some users have different vaults for different
     aspects of their lives, such as Work or Personal but I keep everything
     under one vault for ease of use.

  5. Next setting is Location, click Browse. This is where your vault will be
     locally saved. I created an Obsidian folder in the Documents folder but you
     can put it anywhere you like.

  6. Click Create and Obsidian should open up to your newly created vault with 3
     window panes. Next step is to setup the LiveSync plugin.

### Obsidian - LiveSync Plugin

  1. Click on options button (sprocket icon) on the bottom left area.

  2. Click Community plugins and click on the Turn on community plugins button
     after reading the risk disclosure.

  3. Next to Community plugins click on the Browse button.

  4. Search for Self-hosted LiveSync.

  5. Only 1 plugin should show up and that's the one by voratamoroz, click on
     it.

  6. Click the Install button and let it install.

  7. Click the Enable button.

  8. Click Open setting dialog button.

  9. Click Options button.

  10. Under Settings for Self-hosted LiveSync. you should see a row of 8
      buttons, click on the 4th button with the 🛰️ satellite icon.

  11. This is where we will enter the self-hosted CouchDB details. Next to
      Remote Type make sure CouchDB is selected from the drop down menu.

  12. In the URI field type http://192.168.1.0:5984 make sure to change to your
      server IP and port.

  13. In the Username field type osidian_user or whatever you used in the docker
      compose.

  14. Same for Password field.

  15. In the Database name field type obsidiandb or whatever you named your
      database earlier in CouchDB.

  16. Click the Test button to test the connection to the CouchDB database.
      Assuming everything is working properly a text popup should say Connected
      to obsidiandb successfully.

  17. Click the Check button to confirm the database was configured properly,
      there should be a purple checkmark next to each line item. If not, there
      should be a Fix button next to the item that you can click for it to
      either create or correct for you, but I prefer to manually do it myself.

  18. Assuming everything is good up to this point, click the Apply button next
      to Apply Settings.

  19. Optional but recommended: scroll down to the End-to-end encryption and
      toggle it on and set a passphrase. Please remember this passphrase as all
      your other devices must have matching passphrases for it to be able to
      decrypt your notes. Click the red button Just apply.

  20. On the top menu, under Settings for Self-hosted LiveSync. you should see a
      row of 8 buttons, click on the 5th button with the 🔄 refresh icon.

  21. Next to Sync mode select LiveSync from the drop down menu.

  22. You can close the settings windows out, on the top right of the notes you
      should see Sync: zZz which means everything is working properly and the
      sync is in standby mode until you start typing something.

  23. Repeat the above instructions for all other devices.

### Reverse Proxy

I highly recommend putting this behind at least a reverse proxy, I use Nginx
Proxy Manager in conjunction with Cloudflare Tunnels. You will definitely need
to if you plan on using mobile devices as they require HTTPS.

### Conclusion

Hope this gets you up and running. As you get more familiar with the app, you
will unlock just how great Obsidian is. Happy to answer any questions.
