FROM ubuntu:latest
RUN apt update && apt install -y wget cowsay recode jshon
CMD ["/bin/bash", "-c", "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"]
