# games-docker
Docker image for hosting a [games instance](https://github.com/skiqqy/games).

## Building
```
$ sudo docker build -t "games:latest" .
```

## Running
$ docker run --name games \
		-p 80:80 \
		games:latest

## Other
Once built and the docker container has been run, you can go to `https://localhost:80/` and access the games.
