# DeFrag Server Bundle

This repository allows you to create a Quake 3 DeFrag server with minimal efforts, with the help of Docker, or manually if you're brave enough.

## Cloning this repository

Due to **_very strict_** foldernames required for this project, please clone this repository using this command:

```sh
git clone https://github.com/Defrag-racing/defrag-server-bundle.git ./dfsv
```

## Minimum requirements:
- A 64 bit Debian-based Linux system
- 150MB of RAM per server
- Around 2GB of free storage
- NFS client support (`nfs-common` package)

## Deploying the servers (Docker) - RECOMMENDED METHOD
1. **Make sure Docker is installed**.
2. Create a regular user called `q3df` (**very important**).
3. Make sure the `q3df` user has permissions to get the `docker` group. (`sudo usermod -aG docker q3df`). 
4. Log as `q3df` and `git clone` this repository.
5. Inside the folder, build the docker image (`docker build -t q3df .`).
6. As `q3df`, run `./download_defrag.sh` to download all required files for defrag.
7. Once done, configure `sv.conf` to your likings.
8. Run `generate_docker_service.sh` to generate a `docker-compose.override.yml` file. Review the data if necessary.
9. Run `docker compose up -d` to run it in the background. Test if everything works properly by connecting to your server.

## Deploying the servers (Native/No-Docker Method) - FOR ADVANCED USERS ONLY
1. Create a regular user called `q3df` (**very important**), log into that user and `git clone` this repository. 
2. As root, run `./.localinstall/install.sh` to install all required packages.
3. As `q3df`, run `./download_defrag.sh` 
4. Configure `sv.conf` to your liking.
5. Once done, run `./start-servers.sh` to and verify if there are indeed screens ( `screen -r` should redirect you to the quake 3 console). 
6. Try connecting to your server on your defrag client (`connect ip:port` in the console) to see if you can join it.
7. As root, make a symlink of the NFS mount for custom maps (`sudo ln -s /home/q3df/dfsv/.localinstall/home-q3df-game-nfs-maps.mount /etc/systemd/system/home-q3df-game-nfs-maps.mount`) and start the service (`systemctl enable home-q3df-game-nfs-maps.mount && systemctl start home-q3df-game-nfs-maps.mount`)
8. As root, make a symlink of the dfsv service to run it after each reboot (`sudo ln -s /home/q3df/dfsv/.localinstall/dfsv.service /etc/systemd/system/dfsv.service`) and start the service (`systemctl enable dfsv.service && systemctl start dfsv.service`)
9. GLHF :)

## Customization
1. ssh into your instance
2. run `cd ~/dfsv`
3. run `nano sv.conf`
 - To set a permanent hostname, rcon, admin, and location, fill in the information in the first block
 - To make your server private, modify the "Server privacy" block. Set SV_PRIVATE to 1 and replace the default password to the desired one
 - To control how many and what types of servers to deploy, modify the "Server counts" block. (e.g set `mixed_count=3` for 3 mixed servers)
 - To modify the suffixes (- mixed 1, mixed 2, teamruns 1, etc.) Modify the `Server suffixes` block.
4. Once ready, press Ctrl + x
8. Type 'y', then press 'Enter'
9. rerun `./launch-native.sh` and to apply changes
10. run `ps aux | grep oDFe.ded` to see your running servers and their ports

## Uploading custom maps (if the map is not provided by ws.q3df.org)

After following the previous steps, you will have all current maps from ws.q3df.org on-demand. However, if you'd like to upload custom maps or maps not present in worldspawn, either upload pk3 files directly to `baseq3`, or :

From your local PC:
1. from the machine that contains the desired map, run (from a powershell window or command line):
- `scp path/to/your/map q3df@ipofyourinstance:~/dfsv/game/baseq3`
2. Enter your instance's password.
3. Restart your server from the game by callvoting the current map.
4. Callvote your map

From the instance OS, as user `q3df`:
1. run `cd ~/dfsv/game/baseq3`
2. run `wget link-to-map`
3. Restart your server from the game by callvoting the current map.
4. Callvote your map.

### Quickly migrating to a new location while keeping settings
1. Once you have all your desired settings, you can create a snapshot for free (at the time of this writeup) on vultr.
2. Click on the instance with all your settings
3. Go to the 'snapshots' tab
4. Create snapshot, enter whatever name suitable.
5. Re-do the deployment steps from the beginning of this readme, this type choosing "Snapshot" instead of "64 Bit OS"
6. Choose the snapshot with the name you chose in step 4.
7. Deploy. Once done installing, everything will be up but in your new location. Try connecting via defrag.
8. Destroy unused instances to avoid unecessary billing.

## Auto-uploading demos (Dockerless only)

**If you are running a Docker server, simply edit the required info within `sv.conf`**.

If you were provided a RSID (More information at https://defrag.racing), this step is REQUIRED for proving runs made online.

1) As `q3df`, type this command to edit your crontab file :

```sh
crontab -e
```

Then at the end of it, copy/paste this command:
```
*/30 * * * * cd ~/dfsv && bash ./.docker-demoupload/upload_demos.sh
```

This will automatically send demos to defrag-racing's server every 30 minutes.

## Troubleshooting

### I set `MDD_ENABLED` to 1, but my server suddenly doesn't run...
You need to actually do a few more steps in order to use this feature, such as having unique rs_IDs, otherwise the server won't run. 

Please go to the [defrag.racing](https://defrag.racing/) community for more information.

### The server seems to run, but I see this message:  "VM_LoadDLL 'defrag/qagamei386.so' failed"...
You might have libraries missing, but most likely `libmysqlclient.so.20` on your system. To verify what libraries you might not have, type this :

```sh
ldd ./game/defrag/qagamei386.so
```

If it wasn't installed, a `.deb` package is available inside the `.install` subdirectory.

### I see Sys_Error: Unable to create directory "/server/.q3a", error is Permission denied(13)
If you are running Docker, simply recreate a folder named `.q3a` within the `game` folder. 
If you are not running Docker, create a folder named `.q3a` within your `$HOME` directory. 


### Renting a VPS

If you do not have a server ready, you can rent a VPS:

Options:
- https://www.vultr.com/ < cheap and good quality
- https://aws.amazon.com/
- https://azure.microsoft.com/en-us/
- https://www.digitalocean.com/
- https://www.linode.com/

*I will show the steps for vultr, as it is the easiest to set up.*
1. Sign up
2. Click on the big '+' sign or find "Deploy New Server"
3. Choose "Cloud Compute"
4. Choose desired location
5. Choose 64 Bit Ubuntu (latest version)
6. Choose the $5/mo option (1 CPU 1 Mb RAM). (Billed per hour of usage)
7. Click on "Deploy Now". Wait for server to finish installing
8. Once finished, click on the instance to see the details. You will see ip, username, and password.
9. From a Powershell window (should be installed in your windows already) or command line, execute the following command:
- `ssh root@ipofyourinstance`
- Enter the password, proceed to next section.


## Credits
- **frog** for [its original work](https://github.com/JBustos22/dfsv).
- **Ch0wW** for rewriting parts of the project for [defrag.racing](https://defrag.racing/).