FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget cowsay recode jshon
CMD ["/bin/bash", "-c", "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"]
