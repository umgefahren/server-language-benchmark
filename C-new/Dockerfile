FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y cmake build-essential valgrind

COPY . .

RUN mkdir build
WORKDIR build/
RUN cmake ..
RUN make

CMD ["bash"]