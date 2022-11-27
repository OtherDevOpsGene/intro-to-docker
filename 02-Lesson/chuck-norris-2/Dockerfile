FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget cowsay recode jshon
CMD ["/bin/bash", "-c", "wget 'http://api.chucknorris.io/jokes/random' -qO- | jshon -e value -u | recode html | /usr/games/cowsay"]
