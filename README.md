# docker-presence-monitor

Docker container image for the bluetooth presence monitor found [here](https://github.com/andrewjfreyer/monitor)

## Usage

```bash
docker run -d \
    --name monitor \
    --net host \
    --privileged \
    --volume /path/to/your/config:/config \
    mashupmill/presence-monitor
```

You can also pass additional options (i.e. `-b -tad`) to the end of the command. For example...

```bash
docker run -d \
    --name monitor \
    --net host \
    --privileged \
    --volume /path/to/your/config:/config \
    mashupmill/presence-monitor \
    -b -tad
```